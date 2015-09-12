object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Tardsplaya'
  ClientHeight = 284
  ClientWidth = 622
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar1: TStatusBar
    Left = 0
    Top = 265
    Width = 622
    Height = 19
    Panels = <
      item
        Text = 'Chunk Queue: 0'
        Width = 50
      end>
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 622
    Height = 265
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 1
    object TabSheet1: TTabSheet
      Caption = 'Main'
      object lblChannel: TLabel
        Left = 199
        Top = 3
        Width = 43
        Height = 13
        Caption = 'Channel:'
      end
      object lblQuality: TLabel
        Left = 199
        Top = 49
        Width = 38
        Height = 13
        Caption = 'Quality:'
      end
      object lblClusterTitle: TLabel
        Left = 199
        Top = 219
        Width = 38
        Height = 13
        Caption = 'Cluster:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblClusterVal: TLabel
        Left = 243
        Top = 219
        Width = 4
        Height = 13
        Caption = '-'
      end
      object lblTardsNet: TLabel
        Left = 566
        Top = 221
        Width = 45
        Height = 13
        Cursor = crHandPoint
        Caption = 'tards.net'
        OnClick = lblTardsNetClick
      end
      object lblFavorites: TLabel
        Left = 3
        Top = 3
        Width = 49
        Height = 13
        Caption = 'Favorites:'
      end
      object lblSectionsVal: TLabel
        Left = 567
        Top = 25
        Width = 13
        Height = 13
        Alignment = taCenter
        AutoSize = False
        Caption = '4'
      end
      object lblSectionsTitle: TLabel
        Left = 536
        Top = 3
        Width = 44
        Height = 13
        Caption = 'Sections:'
      end
      object edtChannel: TEdit
        Left = 199
        Top = 22
        Width = 190
        Height = 21
        TabOrder = 0
      end
      object btnLoad: TButton
        Left = 395
        Top = 22
        Width = 76
        Height = 21
        Caption = '1. Load'
        TabOrder = 1
        OnClick = btnLoadClick
      end
      object btnWatch: TButton
        Left = 395
        Top = 68
        Width = 76
        Height = 21
        Caption = '2. Watch'
        Enabled = False
        TabOrder = 2
        OnClick = btnWatchClick
      end
      object lstQuality: TListBox
        Left = 199
        Top = 68
        Width = 190
        Height = 145
        Enabled = False
        ItemHeight = 13
        TabOrder = 3
        OnClick = lstQualityClick
      end
      object lstFavorites: TListBox
        Left = 3
        Top = 22
        Width = 190
        Height = 191
        DragMode = dmAutomatic
        ItemHeight = 13
        TabOrder = 4
        OnClick = lstFavoritesClick
        OnDblClick = lstFavoritesDblClick
        OnDragDrop = lstFavoritesDragDrop
        OnDragOver = lstFavoritesDragOver
        OnMouseDown = lstFavoritesMouseDown
      end
      object btnAddFavorite: TButton
        Left = 3
        Top = 215
        Width = 33
        Height = 17
        Caption = 'Add'
        TabOrder = 5
        OnClick = btnAddFavoriteClick
      end
      object btnDeleteFavorite: TButton
        Left = 111
        Top = 217
        Width = 42
        Height = 17
        Caption = 'Delete'
        Enabled = False
        TabOrder = 6
        OnClick = btnDeleteFavoriteClick
      end
      object btnEditFavorite: TButton
        Left = 159
        Top = 217
        Width = 34
        Height = 17
        Caption = 'Edit'
        Enabled = False
        TabOrder = 7
        OnClick = btnEditFavoriteClick
      end
      object btnCheckVersion: TButton
        Left = 536
        Top = 195
        Width = 75
        Height = 20
        Caption = 'Check Version'
        TabOrder = 8
        OnClick = btnCheckVersionClick
      end
      object btnIncSections: TButton
        Left = 586
        Top = 22
        Width = 25
        Height = 21
        Caption = '+'
        Enabled = False
        TabOrder = 9
        OnClick = btnIncSectionsClick
      end
      object btnDecSections: TButton
        Left = 536
        Top = 22
        Width = 25
        Height = 21
        Caption = '-'
        TabOrder = 10
        OnClick = btnDecSectionsClick
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Log'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object chkAutoScroll: TCheckBox
        Left = 541
        Top = 3
        Width = 70
        Height = 17
        Caption = 'Auto scroll'
        TabOrder = 0
      end
      object chkEnableLogging: TCheckBox
        Left = 3
        Top = 3
        Width = 110
        Height = 17
        Caption = 'Enable logging'
        Checked = True
        State = cbChecked
        TabOrder = 1
      end
      object lvLog: TListView
        Left = 0
        Top = 26
        Width = 614
        Height = 211
        Align = alBottom
        Columns = <
          item
            Caption = 'Time'
            Width = 80
          end
          item
            Caption = 'Log'
            Width = 470
          end>
        ColumnClick = False
        GridLines = True
        ReadOnly = True
        RowSelect = True
        PopupMenu = PopupMenu1
        TabOrder = 2
        ViewStyle = vsReport
      end
      object chkLogOnlyErrors: TCheckBox
        Left = 119
        Top = 3
        Width = 98
        Height = 17
        Caption = 'Log only errors'
        Checked = True
        State = cbChecked
        TabOrder = 3
      end
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 304
    Top = 144
    object Clear1: TMenuItem
      Caption = 'Clear'
      OnClick = Clear1Click
    end
  end
  object MainMenu1: TMainMenu
    Left = 424
    Top = 152
    object File1: TMenuItem
      Caption = 'File'
      object Exit1: TMenuItem
        Caption = 'Exit'
        OnClick = Exit1Click
      end
    end
    object ools1: TMenuItem
      Caption = 'Tools'
      object Settings1: TMenuItem
        Caption = 'Settings'
        OnClick = Settings1Click
      end
    end
  end
end
