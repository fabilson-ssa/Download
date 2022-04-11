unit Model.Interfaces;

interface

uses Controller.Interfaces;

type

  IModelHTTPRequest = interface
    ['{B563246C-6ADB-4707-808B-BAB1945A1819}']

    procedure StartDownload(url, destiny: String);
    procedure StopDownload;
    function IsDownloading: Boolean;
    function GetObserver: IDownloadSubjet;
  end;

implementation

end.
