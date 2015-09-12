object Form2: TForm2
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Tardsplaya - Settings'
  ClientHeight = 243
  ClientWidth = 537
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    537
    243)
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 184
    Top = 170
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Save'
    TabOrder = 0
    OnClick = Button1Click
    ExplicitTop = 85
  end
  object Button2: TButton
    Left = 265
    Top = 170
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = Button2Click
    ExplicitTop = 85
  end
  object Button4: TButton
    Left = 184
    Top = 201
    Width = 156
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Reset to Default'
    TabOrder = 2
    OnClick = Button4Click
    ExplicitTop = 116
  end
  object CheckBox1: TCheckBox
    Left = 8
    Top = 139
    Width = 209
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Auto-confirm when deleting Favorites'
    TabOrder = 3
    ExplicitTop = 54
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 8
    Width = 521
    Height = 125
    Caption = 'Player Settings'
    TabOrder = 4
    object Label1: TLabel
      Left = 16
      Top = 70
      Width = 249
      Height = 13
      Caption = 'Player command-line argument (for standard input):'
    end
    object Label3: TLabel
      Left = 16
      Top = 24
      Width = 59
      Height = 13
      Caption = 'Player Path:'
    end
    object Button3: TButton
      Left = 471
      Top = 43
      Width = 33
      Height = 21
      Caption = '...'
      TabOrder = 0
      OnClick = Button3Click
    end
    object Edit1: TEdit
      Left = 16
      Top = 43
      Width = 449
      Height = 21
      TabOrder = 1
    end
    object Edit2: TEdit
      Left = 16
      Top = 89
      Width = 169
      Height = 21
      TabOrder = 2
    end
  end
end
