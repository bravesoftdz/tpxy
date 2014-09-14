object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Throttle Proxy'
  ClientHeight = 300
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object mLog: TMemo
    Left = 0
    Top = 0
    Width = 635
    Height = 300
    Align = alClient
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object MainMenu1: TMainMenu
    Left = 360
    Top = 112
    object File1: TMenuItem
      Caption = '&File'
      object Exit1: TMenuItem
        Action = actFileExit
      end
    end
    object Edit1: TMenuItem
      Caption = '&Edit'
      object Clear1: TMenuItem
        Action = actEditClear
      end
    end
    object Proxy1: TMenuItem
      Caption = '&Proxy'
      object Active1: TMenuItem
        Action = actProxyActive
      end
      object MaxSpeed1: TMenuItem
        Action = actProxySpeed
      end
    end
  end
  object ActionList1: TActionList
    Left = 288
    Top = 176
    object actFileExit: TAction
      Category = 'File'
      Caption = 'E&xit'
      OnExecute = actFileExitExecute
    end
    object actProxyActive: TAction
      Category = 'Proxy'
      Caption = 'Active'
      OnExecute = actProxyActiveExecute
      OnUpdate = actProxyActiveUpdate
    end
    object actProxySpeed: TAction
      Category = 'Proxy'
      Caption = 'Max. Speed...'
      OnExecute = actProxySpeedExecute
    end
    object actEditClear: TAction
      Category = 'Edit'
      Caption = 'Clear'
      OnExecute = actEditClearExecute
    end
  end
  object ipsMain: TIdSocksServer
    Bindings = <>
    OnConnect = ipsMainConnect
    AllowSocks4 = True
    AllowSocks5 = True
    NeedsAuthentication = False
    OnBeforeSocksConnect = ipsMainBeforeSocksConnect
    Left = 96
    Top = 88
  end
  object idThrottle: TIdInterceptThrottler
    OnConnect = idThrottleConnect
    OnDisconnect = idThrottleDisconnect
    OnReceive = idThrottleReceive
    OnSend = idThrottleSend
    BitsPerSec = 2400
    RecvBitsPerSec = 2400
    SendBitsPerSec = 2400
    Left = 192
    Top = 72
  end
end
