unit frmSettings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.IniFiles;

type
  TForm2 = class(TForm)
    Edit1: TEdit;
    Label3: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    CheckBox1: TCheckBox;
    Label1: TLabel;
    Edit2: TEdit;
    GroupBox1: TGroupBox;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
    procedure ResetToDefault();
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

Uses Unit1;

{$R *.dfm}

procedure TForm2.Button1Click(Sender: TObject);
var
  IniFile : TIniFile;
begin
  if Edit1.Text = '' then
  begin
    PlayerPath := defaultPlayerPath;
  end
  else
  begin
    PlayerPath := Edit1.Text;
  end;

  PlayerCmd := Edit2.Text;

  AutoConfirmFavoriteDeletion := CheckBox1.Checked;

  IniFile := TIniFile.Create(ChangeFileExt(Application.ExeName,'.ini'));
  try
    IniFile.WriteString('Settings', 'PlayerPath', Edit1.Text);
    IniFile.WriteString('Settings', 'PlayerCmd', Edit2.Text);
    IniFile.WriteBool('Settings', 'AutoConfirmFavoriteDeletion', CheckBox1.Checked);
  finally
    IniFile.Free;
  end;
  Close();
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  Close();
end;

procedure TForm2.Button3Click(Sender: TObject);
var
  dialog: TOpenDialog;
  tmpStr: string;
begin
  dialog := TOpenDialog.Create(Self);
  dialog.Options := [ofFileMustExist, ofReadOnly, ofEnableSizing];
  dialog.Filter := 'Executable File (*.exe)|*.exe';
  dialog.InitialDir := ExtractFilePath(ParamStr(0));
  try
    if dialog.Execute then
    begin
      tmpStr := dialog.FileName;
      tmpStr := tmpStr.Replace(ExtractFilePath(ParamStr(0)), '');
      Form2.Edit1.Text := tmpStr;
    end;
  finally
    dialog.Free;
  end;
end;

procedure TForm2.ResetToDefault();
begin
  Edit1.Text := defaultPlayerPath;
  Edit2.Text := defaultPlayerCmd;
  CheckBox1.Checked := False;
end;

procedure TForm2.Button4Click(Sender: TObject);
begin
  ResetToDefault();
end;

procedure TForm2.FormCreate(Sender: TObject);
var
   IniFile : TIniFile;
   fn: string;
begin
  SetFormIcons(Handle, 'MAINICON', 'MAINICON');

  fn := ChangeFileExt(Application.ExeName,'.ini');
  if FileExists(fn) then
  begin
    IniFile := TIniFile.Create(fn);
    try
      Edit1.Text := IniFile.ReadString('Settings', 'PlayerPath', defaultPlayerPath);
      Edit2.Text := IniFile.ReadString('Settings', 'PlayerCmd', defaultPlayerCmd);
      CheckBox1.Checked := IniFile.ReadBool('Settings', 'AutoConfirmFavoriteDeletion', False);
    finally
      IniFile.Free;
    end;
  end
  else
  begin
    ResetToDefault();
  end;
end;

end.
