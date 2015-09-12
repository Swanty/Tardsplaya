program Tardsplaya;

{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

uses
  Windows,
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas',
  uHash in 'uHash.pas',
  frmSettings in 'Forms\frmSettings.pas' {Form2};

{$IFDEF RELEASE}
{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED or
               IMAGE_FILE_DEBUG_STRIPPED or
               IMAGE_FILE_LINE_NUMS_STRIPPED or
               IMAGE_FILE_LOCAL_SYMS_STRIPPED}
{$ENDIF}

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
