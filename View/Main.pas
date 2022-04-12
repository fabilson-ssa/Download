unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Imaging.pngimage,
  Vcl.Buttons, Vcl.FileCtrl,
  ExceptionHandler, System.ImageList, Vcl.ImgList, Vcl.VirtualImageList,
  Vcl.BaseImageCollection, Vcl.ImageCollection,
  Vcl.Samples.Gauges, Data.DB, Vcl.Grids, Vcl.DBGrids,
  System.IOUtils,
  Controller.Interfaces, Controller.HTTPRequest, Controller.Database,
  Download.Types,
  Model.Download,
  Download.Utils;

// Alguns endereços comtendo arquivos de testes para serrem baixados.
const
      url_default_01mb = 'https://proof.ovh.net/files/1Mb.dat'; // https
      url_default_05mb = 'http://212.183.159.230/5MB.zip';
      url_default_10mb = 'http://212.183.159.230/10MB.zip';
      heigh_form_default = 440;

type
  TMainForm = class(TForm, IDownloadObserver)
    pcDownload: TPageControl;
    VirtualImageList16: TVirtualImageList;
    tsDownload: TTabSheet;
    pnlHeader: TPanel;
    Label4: TLabel;
    edtURL: TEdit;
    Label5: TLabel;
    edtDestino: TEdit;
    ImageCollection: TImageCollection;
    tsHistorico: TTabSheet;
    VirtualImageList48: TVirtualImageList;
    Label6: TLabel;
    edDiretorioPadrao: TEdit;
    FileOpenDialog: TFileOpenDialog;
    grdHistorico: TDBGrid;
    dsHistorico: TDataSource;
    pnlProgresso: TPanel;
    gugDownload: TGauge;
    pnlBotton: TPanel;
    plnBotoesAcao: TPanel;
    ImLogo: TImage;
    pnlHeaderHistorico: TPanel;
    edtTamanhoArquivo: TEdit;
    sbIniciar: TButton;
    sbParar: TButton;
    sbDiretorioPadrao: TButton;
    TabSheet1: TTabSheet;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure FormCreate(Sender: TObject);
    procedure sbIniciarClick(Sender: TObject);
    procedure sbPararClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure sbDiretorioPadraoClick(Sender: TObject);
    procedure pcDownloadChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);

  private
    { Private declarations }

    FControllerHTTPRequest: IControllerHTTPRequest;
    FControlerDatabase: IControllerDatabase;

    FUserHadCanceled: Boolean;

    // Método responsável por realizar atualização do formulário, durante o processo de download.
    procedure UpdateForm(Download: TModelDownload);
    // Método responsável por realizar a configuração inicial dos objetos do formulário.
    procedure ConfigInitForm;
    // Método responsável por habilitar/desbilitar os botões de controle do download.
    procedure EnableDownloadButtons(enable: Boolean);
    // Método responsável por atualizar, em tela, os dados vindo do objeto que está sendo "Observado".
    // O TMainForm é o Subject do objeto TDownload, no caso o Observer
    procedure NotifyDownload(Download: TModelDownload);

    procedure EndProcess(Download: TModelDownload);

  public
    { Public declarations }

  end;

var  MainForm: TMainForm;

implementation

{$R *.dfm}

{ TMainForm }
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Define o arquivo default para o download.
  edtURL.Text := url_default_01mb;
//  edtURL.Text := url_default_05mb;
//  edtURL.Text := url_default_10mb;

  // Definie o diretório default para o download.
  edDiretorioPadrao.Text := TWindowsHelper.GetDefaultDownloadFolder;

  // Configura os padrões iniciais da tela.
  ConfigInitForm;

  // Criação do objeto responsável pelo acesso a base de dados.
  FControlerDatabase := TControllerDatabase.New;

  // Criação do objeto responsável pelo gerenciamento do download
  FControllerHTTPRequest := TControllerHTTPRequest.New;

  // Coloca o próprio formulária na lista de objetos "observáveis".
  FControllerHTTPRequest.AddObserver(Self);
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // Antes de finalizar, verifica se ainda existe algum download em andamento.
  if FControllerHTTPRequest.IsDownloading then
    begin
      // Verifica se o usuário deseja realmente interromper o download.
      if MessageBox(0, PChar('Ainda existe download em andamento.'+#13+#10+'Confirma a interrupção?'), PChar('Atenção'), MB_ICONQUESTION or MB_YESNO or MB_SYSTEMMODAL) = mrYes then
        begin
          sbParar.Click;
        end
      else
        Abort;
    end;
end;

procedure TMainForm.sbIniciarClick(Sender: TObject);
var file_name: String;
begin
  // Verifica se os parâmatros necessários para o download estão presentes.
  // Diretório padrão.
  if Length(Trim(edDiretorioPadrao.Text)) > 0 then
    begin
      MessageBox(0, PChar('Um diretório padrão para download precisa ser informado'), PChar('Atenção'), MB_ICONINFORMATION or MB_OK or MB_SYSTEMMODAL);

      exit;
    end;

  // URL.
  if Length(Trim(edtURL.Text)) = 0 then
    begin
      MessageBox(0, PChar('A url para download precisa ser informada'), PChar('Atenção'), MB_ICONINFORMATION or MB_OK or MB_SYSTEMMODAL);

      exit;
    end;

  // Armazena em variável o nome do arquivo, segundo passado na URL.
  file_name := System.IOUtils.TPath.GetFileName(edtURL.Text);

  // Define o destino final do arquivo, com base no diretório escolhido para download e o nome do arquivo.
  edtDestino.Text := System.IOUtils.TPath.Combine(edDiretorioPadrao.Text, file_name);

  // Desabilita alguns componentes, segundo o momento do download.
  EnableDownloadButtons(False);

  // Exibe os objetos responsáveis por reportar o progresso do download.
  pnlProgresso.Visible := True;

  FUserHadCanceled := False;

  // Redimenciona o formulário para comportar agora os objetos objetos responsáveis por reportar o progresso do download.
  Self.Height := heigh_form_default;

  // Aciona o controller responsável pela inicialização do download.
  FControllerHTTPRequest.StartDownload(edtURL.Text, edtDestino.Text);
end;

procedure TMainForm.sbPararClick(Sender: TObject);
begin
  FUserHadCanceled := True;

  // Aciona o controller responsável pela interrupção do download.
  FControllerHTTPRequest.StopDownload;
end;

procedure TMainForm.NotifyDownload(Download: TModelDownload);
begin
  case Download.Status of
    TDownloadStatus.Succeeded: EndProcess(Download);
    TDownloadStatus.Error: EndProcess(Download);
    TDownloadStatus.Downloading: UpdateForm(Download);
  end;
end;

procedure TMainForm.EnableDownloadButtons(enable: Boolean);
begin
  sbDiretorioPadrao.Enabled := enable;
  sbIniciar.Enabled := enable;
  sbParar.Enabled := not enable;
end;

procedure TMainForm.EndProcess(Download: TModelDownload);
begin
  case Download.Status of
    TDownloadStatus.Succeeded:
       begin
         MessageBox(0, PChar('Download realizado com sucesso'), PChar('Atenção'), MB_ICONINFORMATION or MB_OK or MB_SYSTEMMODAL);

         ConfigInitForm;
       end;

    TDownloadStatus.Error:
       begin
         if FUserHadCanceled = True then
           MessageBox(0, PChar('Download interrompido pelo usuário'), PChar('Atenção'), MB_ICONINFORMATION or MB_OK or MB_SYSTEMMODAL)
         else
           MessageBox(0, PChar('Erro ao realizar o download'), PChar('Atenção'), MB_ICONINFORMATION or MB_OK or MB_SYSTEMMODAL);

         ConfigInitForm;
       end;
  end;
end;

procedure TMainForm.ConfigInitForm;
begin
  // Define a "aba" inicial.
  pcDownload.ActivePage := tsDownload;

  // Oculta os objetos responsáveis por reportar o progresso do download.
  pnlProgresso.Visible := False;
  gugDownload.Progress := 0;
  edtTamanhoArquivo.Clear;

  // Incializa a variável responsável por identificar o cancelamento feito pelo usuário.
  FUserHadCanceled := False;

  // Redimenciona o formulário para melhor visualização.
  Self.Height := heigh_form_default;
  Self.Height := Self.Height - pnlProgresso.Height;

  EnableDownloadButtons(True);
end;

procedure TMainForm.sbDiretorioPadraoClick(Sender: TObject);
begin
  if FileOpenDialog.Execute then
    begin
      edDiretorioPadrao.Text := FileOpenDialog.FileName;
    end;
end;

procedure TMainForm.UpdateForm(Download: TModelDownload);
begin
  if Download.Status = TDownloadStatus.Downloading then
    EnableDownloadButtons(False);

  gugDownload.Progress := Round(Download.ProgressPercentage);

  edtTamanhoArquivo.Visible := True;
  edtTamanhoArquivo.Text := TMathHelper.ConvertBytes(Download.CurrentFileSize);

  gugDownload.Visible := True;
  gugDownload.Font.Color := clWhite;
end;

procedure TMainForm.pcDownloadChange(Sender: TObject);
begin
  if pcDownload.ActivePage = tsHistorico then
    begin
      dsHistorico.DataSet := FControlerDatabase.GetAllRecords;
    end;
end;

///////////////////////
procedure TMainForm.Button1Click(Sender: TObject);
begin
  // EConvertError
  try
    StrToInt('A');
  except
    raise EDownloadException.Create('Erro de conversão de tipo');
  end;
end;

procedure TMainForm.Button2Click(Sender: TObject);
var
  N1: integer;
  N2: integer;
  Resultado: integer;
begin
  // EDivByZero
  N1 := 10;
  N2 := 0;
  Resultado := N1 div N2;
  ShowMessage(IntToStr(Resultado));
end;

procedure TMainForm.Button3Click(Sender: TObject);
//var
//  Lista: TObjectList;
//  Objeto: TObject;
begin
  // EListError
//  Lista := TObjectList.Create;
//  try
//    Objeto := Lista.Items[1];
//    ShowMessage(Objeto.ClassName);
//  finally
//    Lista.Free;
//  end;
end;

procedure TMainForm.Button4Click(Sender: TObject);
begin
  // EFOpenError
//  Memo.Lines.LoadFromFile('C:\ArquivoInexistente.txt');
end;

procedure TMainForm.Button5Click(Sender: TObject);
//var ClientDataSet: TClientDataSet;
begin
  // EDatabaseError
//  ClientDataSet := TClientDataSet.Create(nil);
//  try
//    ShowMessage(ClientDataSet.FieldByName('Campo').AsString);
//  finally
//    ClientDataSet.Free;
//  end;
end;


end.
