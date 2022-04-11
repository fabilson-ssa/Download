unit Download.Types;

interface

uses
  System.SysUtils;

type
{$SCOPEDENUMS ON}
  TDownloadStatus = (Null, Downloading, Canceled, Error, NotFound, Succeeded);
{$SCOPEDENUMS OFF}

  TDownloadStatusHelper = record helper for TDownloadStatus
    // Método responsável por retonar uma descrição do status do download.
    function ToString: String;
  end;

  FDownloadException = class(Exception);

implementation

function TDownloadStatusHelper.ToString: String;
begin
  case Self of
    TDownloadStatus.Null:
      Result := 'Vazio'; // Estado inicial.

    TDownloadStatus.Downloading:
      Result := 'Baixando';

    TDownloadStatus.Canceled:
      Result := 'Cancelado';

    TDownloadStatus.Error:
      Result := 'Finalizado com erro';

    TDownloadStatus.NotFound:
      Result := 'Arquivo não localizado';

    TDownloadStatus.Succeeded:
      Result := 'Finalizado com sucesso';
  end;
end;

end.
