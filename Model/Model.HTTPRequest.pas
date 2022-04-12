unit Model.HTTPRequest;

interface

uses System.Generics.Collections, System.Threading,

     IdBaseComponent, IdComponent,
     IdTCPConnection, IdTCPClient, IdHTTP,
     IdAuthentication, IdAntiFreezeBase,
     IdAntiFreeze, IdIOHandler, IdIOHandlerStack,
     IdIOHandlerSocket, IdSSL, IdSSLOpenSSL,
     Model.Interfaces, Model.Database, Model.Download, Model.LogDownload,
     Download.Types, Controller.Interfaces,
     Download.Utils;

type
  TModelHTTPRequest = class(TInterfacedObject, IModelHTTPRequest, IDownloadSubjet)

  private
    FIdHTTP: TIdHTTP;
    FIOHandler: TIdSSLIOHandlerSocketOpenSSL;

    FModelDatabase: TModelDatabase;
    FModelLogDownload: TModelLogDownload;

    // Objeto responsável por impedir o congelamento da aplicação, enquanto é aguardado o final do download.
    IdAntiFreeze: TIdAntiFreeze;

    FTask: ITask;

    // Objeto responsável por definir a lista de outros objetos que serão "observaveis".
    FObservers: TList<IDownloadObserver>;

    FModelDownload: TModelDownload;

    // Método responsável pela inicialização do processo "HTTP Request".
    procedure FIdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
    // Método responsável pelo progresso do processo "HTTP Request".
    procedure FIdHTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
    // Método responsável pela finalização do processo "HTTP Request".
    procedure FIdHTTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
    // Método responsávle por identificar se o arquivo se encontra disponível.
    function CheckFileOnlineExists(url: String): Boolean;
  public
    // Construtor da classe.
    constructor Create;

    // Destrutor da classe.
    destructor Destroy; override;

    // Método responsável por criar uma nova instância do objeto.
    // Uma class function permite que o método possa ser chamado a partir da própria classe, sem a necessidade de se instanciar um objeto dela.
    class function New: IModelHTTPRequest;
    // Método responsável por realizar o download do arquivo.
    procedure StartDownload(url, destiny: String);
    // Método responsável por parar o download do arquivo.
    procedure StopDownload;
    // Método responsável por retornar se existe download em andamento.
    function IsDownloading: Boolean;
    // Método responsável por adicionar um "Observer" a lista.
    procedure AddObserver(Observer: IDownloadObserver);
    // Método responsável por remover um "Observer" da lista.
    procedure RemoveObserver(Observer: IDownloadObserver);
    // Método responsável por retornar o Observer instanciado.
    function GetObserver: IDownloadSubjet;
    // Método responsável por notificar ao objeto "observador" o status do objeto "observado".
    procedure NotifyObserver(Download: TModelDownload);

  end;

implementation

uses System.SysUtils, System.Classes;

{ TModelHTTPRequest }

constructor TModelHTTPRequest.Create;
begin
  FIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  FIOHandler.SSLOptions.Method := sslvSSLv23;

  // Inicialização dos objetos responsáveis por executar o "HTTP Request".
  FIdHTTP := TIdHTTP.Create(nil);
  FIdHTTP.IOHandler := FIOHandler;
  FIdHTTP.OnWork := FIdHTTPWork;
  FIdHTTP.OnWorkBegin := FIdHTTPWorkBegin;
  FIdHTTP.OnWorkEnd := FIdHTTPWorkEnd;

  // Configura a propriedade do objeto para permir redirecionamento, como uma alternativa de localização
  FIdHTTP.HandleRedirects := True;

  // Inicialização do objeto responsável pelo acesso ao banco de dados.
  FModelDatabase := TModelDatabase.Create(nil);

  // Inicialização de uma transação com o banco de dados, pois só serão salvos os registros referentes aos downloads efetivamente concluídos com sucesso.
  FModelDatabase.Connection.StartTransaction;

  // Inicialização do objeto reponsável pelos dados referentes ao download do arquivo.
  FModelDownload := TModelDownload.Create;

  // Inicialização do objeto responsável por impedir o congelamento da aplicação, enquanto é aguardado o final do download.
  IdAntiFreeze := TIdAntiFreeze.Create(nil);

  // Inicialização da lista de "Observers"
  FObservers := TList<IDownloadObserver>.Create;
end;

destructor TModelHTTPRequest.Destroy;
begin
  FreeAndNil(FIOHandler);
  FreeAndNil(FIdHTTP);
  FreeAndNil(IdAntiFreeze);
  FreeAndNil(FModelLogDownload);
  FreeAndNil(FModelDownload);
  FreeAndNil(FModelDatabase);
  FreeAndNil(FObservers);

  inherited;
end;

class function TModelHTTPRequest.New: IModelHTTPRequest;
begin
  Result := Self.Create;
end;

procedure TModelHTTPRequest.StartDownload(url, destiny: String);
var file_ok: Boolean;
begin
  // Verifica se o arquivo está disponível.
  file_ok := CheckFileOnlineExists(url);

  if file_ok then
    begin
      // Realiza a inclusão do registro na base de dados, responsável pelo controle do início do download.
      FModelLogDownload := FModelDatabase.SetDownloadStart(url);

      // Verifica se objeto foi devidademente criado e preenchido,
      if FModelLogDownload <> nil then
        begin
          FTask := TTask.Create(
                                  procedure
                                    begin
                                      TThread.Synchronize(TThread.CurrentThread,
                                      procedure
                                      var FileStream: TFileStream;
                                      begin
                                        // Inicilização do objeto responsável por criar o arquivo.
                                        FileStream := TFileStream.Create(destiny, fmCreate);

                                        try
                                          FIdHTTP.CleanupInstance;

                                          try
                                            FIdHTTP.Get(url, FileStream);

                                          except
                                            on E:Exception do
                                              begin
                                                FModelDownload.Status := TDownloadStatus.Error;

                                                if Lowercase(e.Message) <> 'operation cancelled' then
                                                  FModelDownload.ErrorMessage := e.Message;

                                                // Notifica ao objeto "observador" o status do objeto "observado". (Finalizado)
                                                NotifyObserver(FModelDownload);
                                              end;
                                          end;
                                        finally
                                          FreeAndNil(FileStream);
                                        end;
                                      end
                                      );
                                    end
                               );

          try
            FTask.Start;
          except
            on E:Exception do
            begin
              FModelDownload.ErrorMessage := 'Erro ao rodar a thread: ' + e.Message;
              FModelDownload.Status := TDownloadStatus.Error;

              if FModelDatabase.Connection.InTransaction then
                FModelDatabase.Connection.Rollback;

              // Notifica ao objeto "observador" o status do objeto "observado". (Finalizado)
              NotifyObserver(FModelDownload);
            end;
          end;

        end;

    end
  else
    begin
      FModelDownload.Status := TDownloadStatus.NotFound;

      // Notifica ao objeto "observador" o status do objeto "observado". (Arquivo não localizado)
      NotifyObserver(FModelDownload);
    end;
end;

procedure TModelHTTPRequest.StopDownload;
begin
  // Efetua o rollback da transação, uma vez que foi solicitada a interrupção do download.
  if FModelDatabase.Connection.InTransaction then
    FModelDatabase.Connection.Rollback;

  FTask.Cancel;
end;

function TModelHTTPRequest.IsDownloading: Boolean;
begin
  Result := False;

  if Assigned(FTask) then
    result := (FTask.Status = TTaskStatus.Running);
end;

procedure TModelHTTPRequest.FIdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
begin
  // Atribui ao objeto, o status de "Baixando".
  FModelDownload.Status := TDownloadStatus.Downloading;

  // Atribui ao objeto, o tamanho do arquivo.
  FModelDownload.FileSize := AWorkCountMax;

  // Notifica ao objeto "observador" o status do objeto "observado". (Baixando)
  NotifyObserver(FModelDownload);
end;

procedure TModelHTTPRequest.FIdHTTPWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
begin
  // Verifica se o processo foi cancelado.
  FTask.CheckCanceled;

  // Atribui ao objeto, o status de "Baixando".
  FModelDownload.Status := TDownloadStatus.Downloading;

  // Atribui ao objeto, o tamanho (bytes) atual do arquivo, durante o processo de download.
  FModelDownload.CurrentFileSize := AWorkCount;

  // Atribui ao objeto, o percentual atual do arquivo, durante o processo de download.
  FModelDownload.ProgressPercentage := TMathHelper.Percentage(AWorkCount, FModelDownload.FileSize);

  // Notifica ao objeto "observador" o status do objeto "observado". (Baixando)
  NotifyObserver(FModelDownload);
end;

procedure TModelHTTPRequest.FIdHTTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
  if FTask.Status = TTaskStatus.Canceled then
    begin
      FreeAndNil(FModelLogDownload);
    end
  else
    begin
      if (FModelDownload.CurrentFileSize = FModelDownload.FileSize) then
        begin
          FModelDatabase.SetDownloadEnd(FModelLogDownload.Codigo);

          if FModelDatabase.Connection.InTransaction then
            FModelDatabase.Connection.Commit;

          FModelDownload.ProgressPercentage := 100;

          FreeAndNil(FModelLogDownload);

          // Atribui ao objeto, o status de "Finalizado com sucesso".
          FModelDownload.Status := TDownloadStatus.Succeeded;

          // Notifica ao objeto "observador" o status do objeto "observado". (Finalizado com sucesso)
          NotifyObserver(FModelDownload);
        end;
    end;
end;

function TModelHTTPRequest.CheckFileOnlineExists(url: String): Boolean;
var file_size: Int64;
begin
  FIdHTTP.CleanupInstance;

  try
    FIdHTTP.Head(url);

    file_size := FIdHTTP.Response.ContentLength;

    Result :=  file_size > 0;
  except on E: EIdHTTPProtocolException do
    begin
      // Tratar alguma exceção.
    end;
  end;
end;

procedure TModelHTTPRequest.AddObserver(Observer: IDownloadObserver);
begin
  FObservers.Add(Observer);
end;

procedure TModelHTTPRequest.RemoveObserver(Observer: IDownloadObserver);
begin
  FObservers.Delete(FObservers.IndexOf(Observer));
end;

function TModelHTTPRequest.GetObserver: IDownloadSubjet;
begin
  Result := Self;
end;

procedure TModelHTTPRequest.NotifyObserver(Download: TModelDownload);
var Observer: IDownloadObserver;
begin
  for Observer in FObservers do
    begin
      Observer.NotifyDownload(Download);
    end;
end;

end.
