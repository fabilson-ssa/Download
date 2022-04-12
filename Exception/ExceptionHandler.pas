unit ExceptionHandler;

interface

uses
  System.SysUtils, Vcl.Forms;

type

  TExceptionHandler = class
  private
    { Private declarations }

    LogPath: String;
    LogPathScreenshots: String;
    LogFile: TextFile;
    FullNamePath: String;
    DateTime: String;

    // Método responsável por retornar o login do usuário do Windows.
    function GetLogedUserName: String;
    // Método responsável por retornar a versão do Windows.
    function GetWindowsVersion: String;
    // Método responsável por salvar uma imagem da exceção.
    procedure SaveFormImageException(FileName: String; Form: TForm);
    procedure SaveFormImageExceptionAsBMP(FileName: String; Form: TCustomForm);
  public
    { Public declarations }

    // Construtor da classe.
    constructor Create;

    // Método responsável por tratar as exceções.
    procedure HandleException(Sender: TObject; E: Exception);

  end;

implementation

uses
  Winapi.Windows, Win.Registry, System.UITypes,
  System.IOUtils,
  Vcl.Dialogs, Vcl.Graphics, Vcl.Imaging.jpeg, Vcl.ClipBrd,
  System.Classes,
  Vcl.ComCtrls;

var
  FException: TExceptionHandler;

{ TExceptionHandler }
constructor TExceptionHandler.Create;
begin
  Application.OnException := HandleException;

  DateTime := FormatDateTime('dd-mm-yyyy_hh-nn-ss', Now);

  LogPath := System.SysUtils.GetCurrentDir + '\log';

  // Cria o diretório de log.
  System.SysUtils.ForceDirectories(LogPath);

  LogPathScreenshots := System.SysUtils.GetCurrentDir + '\log\screenshots';

  // Cria o diretório de screenshots.
  System.SysUtils.ForceDirectories(LogPathScreenshots);

  FullNamePath := System.IOUtils.TPath.Combine(LogPath, 'log.txt');
  AssignFile(LogFile, FullNamePath);
end;

procedure TExceptionHandler.HandleException(Sender: TObject; E: Exception);
var StringBuilder: TStringBuilder;
begin
  // Se o arquivo existir, abre para edição,
  // Caso contrário, cria o arquivo.
  if FileExists(FullNamePath) then
    Append(LogFile)
  else
    ReWrite(LogFile);

  WriteLn(LogFile, 'Data/Hora.......: ' + DateTimeToStr(Now));
  WriteLn(LogFile, 'Mensagem........: ' + E.Message);
  WriteLn(LogFile, 'Classe Exceção..: ' + E.ClassName);
  WriteLn(LogFile, 'Formulário......: ' + Screen.ActiveForm.Name);
  WriteLn(LogFile, 'Unit............: ' + Sender.UnitName);
  WriteLn(LogFile, 'Controle Visual.: ' + Screen.ActiveControl.Name);
  WriteLn(LogFile, 'Usuário.........: ' + GetLogedUserName);
  WriteLn(LogFile, 'Versão Windows..: ' + GetWindowsVersion);
  WriteLn(LogFile, StringOfChar('-', 70));

  // Fecha o arquivo
  CloseFile(LogFile);

  // Salva uma imagem (BMP) da tela, onde ocorreu a exceção.
  SaveFormImageExceptionAsBMP(Format('%s\%s.bmp', [LogPathScreenshots, DateTime]), Screen.ActiveForm);

  // O trocho de código abaixo, faz com que seja exibida uma mensagem ao usuário.
  StringBuilder := TStringBuilder.Create;
  try
    // Exibe a mensagem para o usuário
    StringBuilder.AppendLine('Ocorreu um erro na aplicação.')
                 .AppendLine('O problema será analisado pelo desenvolvedor.')
                 .AppendLine('Verifique o arquivo de log para maiores informações.')
                 .AppendLine('Há também uma imagem da tela, onde aconteceu o erro.')
                 .AppendLine(EmptyStr)
                 .AppendLine('Descrição técnica:')
                 .AppendLine(E.Message);

    MessageBox(0, PChar(StringBuilder.ToString), PChar('Atenção'), MB_ICONWARNING or MB_OK or MB_SYSTEMMODAL);

  finally
    StringBuilder.Free;
  end;
end;

function TExceptionHandler.GetLogedUserName: String;
var Size: DWord;
begin
  Size := 1024;
  SetLength(result, Size);
  GetUserName(PChar(result), Size);
  SetLength(result, Size - 1);
end;

function TExceptionHandler.GetWindowsVersion: String;
begin
  case System.SysUtils.Win32MajorVersion of
    5:
      case System.SysUtils.Win32MinorVersion of
        1: result := 'Windows XP';
      end;
    6:
      case System.SysUtils.Win32MinorVersion of
        0: result := 'Windows Vista';
        1: result := 'Windows 7';
        2: result := 'Windows 8';
        3: result := 'Windows 8.1';
      end;
    10:
      case System.SysUtils.Win32MinorVersion of
        0: result := 'Windows 10';
      end;
//    11:
//      case System.SysUtils.Win32MinorVersion of
//        0: result := 'Windows 11';
//      end;
  end;
end;

procedure TExceptionHandler.SaveFormImageException(FileName: String; Form: TForm);
var
  Bitmap: TBitmap;
  JPEG: TJPEGImage;
begin
  Bitmap := TBitmap.Create;
  JPEG := TJPEGImage.Create;
  try
    Bitmap.Assign(Form.GetFormImage);

    JPEG.Assign(Bitmap);
    JPEG.CompressionQuality := 100;

    JPEG.SaveToFile(Format('%s\%s.jpg', [LogPathScreenshots, FileName]));
  finally
    FreeAndNil(JPEG);
    FreeAndNil(Bitmap);
  end;
end;

procedure TExceptionHandler.SaveFormImageExceptionAsBMP(FileName: String; Form: TCustomForm);
var
  Bitmap: TBitMap;
begin
  Bitmap := Form.GetFormImage;

  try
    Bitmap.SaveToFile(FileName);
  finally
    Bitmap.Free;
  end;
end;

initialization
  FException := TExceptionHandler.Create;

finalization
  FException.Free;

end.
