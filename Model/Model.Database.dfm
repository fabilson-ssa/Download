object ModelDatabase: TModelDatabase
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Height = 259
  Width = 485
  PixelsPerInch = 96
  object Connection: TFDConnection
    Params.Strings = (
      'LockingMode=Normal'
      'Database=C:\DownloadApp\bin\database\database.db'
      'DriverID=SQLite'
      'MonitorBy=Remote')
    LoginPrompt = False
    Left = 72
    Top = 16
  end
  object Query: TFDQuery
    Connection = Connection
    SQL.Strings = (
      'select codigo as codigo, '
      'cast(url as character varying(600)) as url, '
      'strftime('#39'%d/%m/%Y %H:%M:%S'#39', datainicio) as datainicio,'
      'strftime('#39'%d/%m/%Y %H:%M:%S'#39', datafim)as datafim'
      'from logdownload'
      '')
    Left = 72
    Top = 88
    object Querycodigo: TFDAutoIncField
      FieldName = 'codigo'
      Origin = 'CODIGO'
      ProviderFlags = [pfInWhere, pfInKey]
      ReadOnly = True
    end
    object Queryurl: TWideStringField
      AutoGenerateValue = arDefault
      FieldName = 'url'
      Origin = 'url'
      ProviderFlags = []
      ReadOnly = True
      Size = 32767
    end
    object Querydatainicio: TWideStringField
      AutoGenerateValue = arDefault
      FieldName = 'datainicio'
      Origin = 'datainicio'
      ProviderFlags = []
      ReadOnly = True
      Size = 32767
    end
    object Querydatafim: TWideStringField
      AutoGenerateValue = arDefault
      FieldName = 'datafim'
      Origin = 'datafim'
      ProviderFlags = []
      ReadOnly = True
      Size = 32767
    end
  end
  object FDPhysSQLiteDriverLink: TFDPhysSQLiteDriverLink
    Left = 224
    Top = 17
  end
  object FDGUIxWaitCursor: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 224
    Top = 88
  end
  object FDGUIxErrorDialog: TFDGUIxErrorDialog
    Provider = 'Forms'
    Left = 224
    Top = 168
  end
  object FDMoniRemoteClientLink: TFDMoniRemoteClientLink
    EventKinds = [ekError, ekConnConnect, ekConnTransact, ekCmdExecute, ekCmdDataIn, ekCmdDataOut, ekAdaptUpdate]
    Tracing = True
    Left = 384
    Top = 16
  end
end
