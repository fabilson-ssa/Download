program Download;

uses
  Vcl.Forms,
  Main in 'View\Main.pas' {MainForm},
  Download.Types in 'Types\Download.Types.pas',
  Controller.Interfaces in 'Controller\Controller.Interfaces.pas',
  Controller.Database in 'Controller\Controller.Database.pas',
  Controller.HTTPRequest in 'Controller\Controller.HTTPRequest.pas',
  Model.Download in 'Model\Model.Download.pas',
  Model.Database in 'Model\Model.Database.pas' {ModelDatabase},
  Model.Interfaces in 'Model\Model.Interfaces.pas',
  Model.HTTPRequest in 'Model\Model.HTTPRequest.pas',
  Model.LogDownload in 'Model\Model.LogDownload.pas',
  ExceptionHandler in 'Exception\ExceptionHandler.pas',
  Download.Utils in 'Utils\Download.Utils.pas';

{$R *.res}

begin
{
   O "Vazamento de Memória" (MemoryLeak) ocorre quando uma determinada rotina não é liberada, este erro pode ocasionar um mal funcionamento na aplicação,
   com o comando ReportMemoryLeaksOnShutdown conseguimos ativar o recurso que mapeará os vazamentos de memória.

   Esta é uma variável global só precisando ser declarada uma unica vez.
}
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
