unit Controller.Database;

interface

uses Data.DB,
     Controller.Interfaces,
     Model.Database;

type

  TControllerDatabase = class(TInterfacedObject, IControllerDatabase)
  private
    { Private declarations }

    FDatabase: TModelDatabase;

  public
    { Public declarations }

    // Construtor da classe.
    constructor Create;
    // Destrutor da classe.
    destructor Destroy; override;
    // Método responsável por criar uma nova instância do objeto.
    // Uma class function permite que o método possa ser chamado a partir da própria classe, sem a necessidade de se instanciar um objeto dela.
    class function New: IControllerDatabase;
    // Método responsável por retornar todos os registros de download.
    function GetAllRecords: TDataSet;
  end;

implementation

uses System.SysUtils;

{ TControllerDatabase }

constructor TControllerDatabase.Create;
begin
  FDatabase := TModelDatabase.Create(nil);
end;

destructor TControllerDatabase.Destroy;
begin
  FreeAndNil(FDatabase);

  inherited;
end;

class function TControllerDatabase.New: IControllerDatabase;
begin
  Result := Self.Create;
end;

function TControllerDatabase.GetAllRecords: TDataSet;
begin
  Result := FDatabase.GetDatasetDownloads;
end;

end.
