unit ExceptionHandler;

interface

uses
  System.SysUtils;

type

  TExceptionHandler = class
  private
    { Private declarations }

  public
    { Public declarations }

    // Construtor da classe.
    constructor Create;

    procedure HandleException(Sender: TObject; E: Exception);

  end;
implementation


{ TExceptionHandler }
constructor TExceptionHandler.Create;
begin

end;

procedure TExceptionHandler.HandleException(Sender: TObject; E: Exception);
begin

end;

end.
