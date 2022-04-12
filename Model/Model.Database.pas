unit Model.Database;

interface

uses
  Vcl.Forms, System.SysUtils, System.StrUtils, System.Classes,
  Winapi.Windows,
  Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs, FireDAC.VCLUI.Wait,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, FireDAC.Comp.UI,
  FireDAC.VCLUI.Error,
  FireDAC.Moni.Base, FireDAC.Moni.RemoteClient,
  Model.LogDownload;

type

  TModelDatabase = class(TDataModule)

    Connection: TFDConnection;
    FDGUIxWaitCursor: TFDGUIxWaitCursor;
    FDPhysSQLiteDriverLink: TFDPhysSQLiteDriverLink;
    FDGUIxErrorDialog: TFDGUIxErrorDialog;
    FDMoniRemoteClientLink: TFDMoniRemoteClientLink;
    Query: TFDQuery;
    Querycodigo: TFDAutoIncField;
    Queryurl: TWideStringField;
    Querydatainicio: TWideStringField;
    Querydatafim: TWideStringField;

    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);

  private
    { Private declarations }

  public
    { Public declarations }

    // Método responsável por registrar no banco de dados, o início do download.
    function SetDownloadStart(url: String): TModelLogDownload;
    // Método responsável por registrar no banco de dados, o término do download.
    procedure SetDownloadEnd(code: Int64);
    // Método responsável por retornar todos os registros de download.
    function GetDatasetDownloads: TDataSet;
  end;

var ModelDatabase: TModelDatabase;

implementation

{$R *.dfm}

{ TModelDatabase }

procedure TModelDatabase.DataModuleCreate(Sender: TObject);
var table_list:  TStringList;
    ok: Boolean;
begin
  table_list := TStringList.Create;

  try
    Connection.Connected := False;
    Connection.Params.Database := ExtractFilePath(Application.ExeName) + 'database\database.db';

    // Armazena em variável todas as tabelas encontradas na base de dados.
    Connection.GetTableNames('', '', '', table_list);

    // Verifica se existe, na base de dados, a tabela (logdownload) necessária a aplicação.
    if table_list.Count > 0 then
      begin
        ok := AnsiContainsText(table_list.Text, 'logdownload');

        try
          // Estabelece a conexão.
          Connection.Connected := True;
        except
          on E: EDatabaseError do
            raise Exception.Create('Exception: ' + E.Message);
        end;

      end
    else
      begin
        MessageBox(0, PChar('Não foi possível localizar a tabela necessária a aplicação'), PChar('Atenção'), MB_ICONERROR or MB_OK or MB_SYSTEMMODAL);

        Application.Terminate;
      end;

  finally
    FreeAndNil(table_list);
  end;
end;

procedure TModelDatabase.DataModuleDestroy(Sender: TObject);
begin
  Query.Close;
  Connection.Connected := False;
end;

function TModelDatabase.SetDownloadStart(url: String): TModelLogDownload;
var LogDownload: TModelLogDownload;
begin
  Query.Close;
  Query.SQL.Clear;

  try
    Query.SQL.Add(' insert into logdownload (url, datainicio) ');
    Query.SQL.Add(' values (:url, :start_date) ');

    Query.ParamByName('url').Value := url;
    Query.ParamByName('start_date').Value := now;

    Query.ExecSQL;

    LogDownload := TModelLogDownload.Create;
    // Retorna como código, o último registro inserido, na sessão.
    LogDownload.codigo := Int64(Connection.GetLastAutoGenValue(''));
    LogDownload.URL := url;
    LogDownload.DataInicio := now;

    Result := LogDownload;
  except
    on E: EDatabaseError do
      begin
        MessageBox(0, PChar('Não foi possível inserir o registro.' +#13+#10 + E.Message), PChar('Atenção'), MB_ICONQUESTION or MB_OK or MB_SYSTEMMODAL);

        Result := nil;
      end;
  end;
end;

procedure TModelDatabase.SetDownloadEnd(code: Int64);
begin
  Query.Close;
  Query.SQL.Clear;

  try
    Query.SQL.Add(' update logdownload ');
    Query.SQL.Add(' set datafim = datetime(''now'', ''localtime'') ');
    Query.SQL.Add(' where codigo = :code ');

    Query.ParamByName('code').Value := code;

    Query.ExecSQL;
  except
    on E: EDatabaseError do
      begin
        MessageBox(0, PChar('Não foi possível atualizar o registro.' +#13+#10 + E.Message), PChar('Atenção'), MB_ICONQUESTION or MB_OK or MB_SYSTEMMODAL)
      end;
  end;
end;

function TModelDatabase.GetDatasetDownloads: TDataSet;
begin
  Query.Close;
  Query.SQL.Clear;

  try
    Query.SQL.Add(' select codigo as codigo, ');
    Query.SQL.Add('        cast(url as character varying(600)) as url, ');
    Query.SQL.Add('        strftime(''%d/%m/%Y %H:%M:%S'', datainicio) as datainicio, ');
    Query.SQL.Add('        strftime(''%d/%m/%Y %H:%M:%S'', datafim) as datafim ');
    Query.SQL.Add(' from logdownload ');
    Query.SQL.Add(' order by codigo desc ');

    Query.Open;
  except
    on E: EDatabaseError do
      begin
        MessageBox(0, PChar('Não foi possível atualizar o registro.' +#13+#10 + E.Message), PChar('Atenção'), MB_ICONQUESTION or MB_OK or MB_SYSTEMMODAL)
      end;
  end;

  Result := Query;
end;

end.
