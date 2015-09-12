unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, superobject, OverbyteIcsUrl, OverbyteIcsHttpProt,
  OverbyteIcsCookies, OverbyteIcsWSocket, OverbyteIcsHttpCCodZLib {gzip},
  System.Generics.Collections,
  OtlThreadPool, OtlComm, OtlTask, OtlTaskControl,
  OtlParallel, OtlCollections, OtlCommon, Unit2,
  Winsock, ShellApi, Vcl.ComCtrls, System.DateUtils,
  uHash, Vcl.Menus, System.IniFiles, frmSettings;



type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    lblChannel: TLabel;
    edtChannel: TEdit;
    btnLoad: TButton;
    lblQuality: TLabel;
    btnWatch: TButton;
    lstQuality: TListBox;
    lblClusterTitle: TLabel;
    lblClusterVal: TLabel;
    chkAutoScroll: TCheckBox;
    chkEnableLogging: TCheckBox;
    lvLog: TListView;
    lblTardsNet: TLabel;
    lblFavorites: TLabel;
    lstFavorites: TListBox;
    btnAddFavorite: TButton;
    btnDeleteFavorite: TButton;
    btnEditFavorite: TButton;
    btnCheckVersion: TButton;
    chkLogOnlyErrors: TCheckBox;
    PopupMenu1: TPopupMenu;
    Clear1: TMenuItem;
    btnIncSections: TButton;
    btnDecSections: TButton;
    lblSectionsVal: TLabel;
    lblSectionsTitle: TLabel;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    ools1: TMenuItem;
    Settings1: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnWatchClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure lstQualityClick(Sender: TObject);
    procedure lblTardsNetClick(Sender: TObject);
    procedure lstFavoritesClick(Sender: TObject);
    procedure lstFavoritesDblClick(Sender: TObject);
    procedure lstFavoritesDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure lstFavoritesDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure lstFavoritesMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnEditFavoriteClick(Sender: TObject);
    procedure btnDeleteFavoriteClick(Sender: TObject);
    procedure btnAddFavoriteClick(Sender: TObject);
    procedure btnCheckVersionClick(Sender: TObject);
    procedure Clear1Click(Sender: TObject);
    procedure btnIncSectionsClick(Sender: TObject);
    procedure btnDecSectionsClick(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure Settings1Click(Sender: TObject);
  private
    FSectionCount: Integer;
    FPlayerHandle: THandle;
    FHelloWorker: IOmniTaskControl;
    FWritingStream: Boolean;
    FStreamUrlQueue: TList<TStreamUrlQueueItem>;
    FStreamUrl: string;
    FStreamPath: string;
    startingPoint: TPoint;
    procedure CheckFavorites();
    procedure SaveFavorites();
    procedure DeleteFavorite;
    procedure DoGetVideo;
    procedure TaskMessageProc(const task: IOmniTaskControl;
      const msg: TOmniMessage);
    procedure UpdateQueueText(q: Integer);
    procedure FreeQualities;
    procedure WriteToLog(str: String; isError: Boolean);
  public
    { Public declarations }
  end;

type
  TFakeClass = class
    IcsCookies: TIcsCookies;
    procedure HTTPSetCookie(Sender: TObject; const Data: String; var Accept: Boolean);
  end;

type
  TExtInf = class
    duration: Double;
    url: string;
    constructor Create(durationStr: string; url: string);
  end;

type
  THelloWorker = class(TOmniWorker)
  strict private
    FStreamUrl   : string;

    FLastTime: TDateTime;

    HttpCli1: THttpCli;
    DataIn: TMemoryStream;
    tmpStr: string;
    strList: TStringList;
    FExtMediaSequence: Integer;
    extInfs: TList<TExtInf>;
  private
  public
    constructor Create(const streamUrl: string);
    destructor Destroy; override;
    function  Initialize: boolean; override;
    procedure StartWork(var msg: TMessage); message MSG_START_WORK;
  end;

type
  TQuality = class
  public
    name: string;
    url: string;
    resolution: string;
    bitrate: string;
  end;

var
  Form1: TForm1;
  PlayerPath: string;
  PlayerCmd: string;
  AutoConfirmFavoriteDeletion: Boolean;
  defaultPlayerPath: string;
  defaultPlayerCmd: string;

procedure SetFormIcons(FormHandle: HWND; SmallIconName, LargeIconName: string);

implementation

{$R *.dfm}

procedure TFakeClass.HTTPSetCookie(Sender: TObject; const Data: String; var Accept: Boolean);
begin
  IcsCookies.SetCookie(Data, (Sender as THttpCli).Url);
end;

function DateTimeToUNIXTimeFAST(DelphiTime: TDateTime): LongWord;
begin
  Result := Round((DelphiTime - 25569) * 86400);
end;

function SplitExt(line: string): TStringList;
var
  tmpStr: string;
begin
  Result := TStringList.Create;
  tmpStr := line;
  tmpStr := tmpStr.Replace('"', '');
  Result.CommaText := tmpStr;
end;

procedure TForm1.WriteToLog(str:String; isError: Boolean);
begin
  if chkEnableLogging.Checked then
  begin
    if ((chkLogOnlyErrors.Checked) and (isError)) or (not chkLogOnlyErrors.Checked) then
    begin
      with lvLog.Items.Add do
      begin
        Caption := FormatDateTime('hh:nn:ss.zzz', Now);
        SubItems.Add(str);
        if chkAutoScroll.Checked then
        begin
          MakeVisible(False);
        end;
      end;
    end;
  end;
end;

function DataInToString(DataIn: TMemoryStream): string;
var
  SR: TStreamReader;
begin
  DataIn.Seek(0, soBeginning);
  SR := TStreamReader.Create(DataIn, TEncoding.UTF8, True);
  try
    Result := SR.ReadToEnd;
  finally
    FreeAndNil(SR);
  end;
end;

procedure TForm1.FreeQualities();
var
  i: Integer;
begin
  lblClusterVal.Caption := '-';
  if lstQuality.Items.Count > 0 then
  begin
    for i := 0 to lstQuality.Items.Count - 1 do
    begin
      lstQuality.Items.Objects[i].Free;
    end;
    lstQuality.Items.Clear;
  end;
end;

procedure TForm1.lblTardsNetClick(Sender: TObject);
begin
  ShellExecute(0, 'OPEN', PWideChar('http://tards.net/'), '', '', SW_SHOWNORMAL);
end;

procedure TForm1.lstQualityClick(Sender: TObject);
begin
  if lstQuality.ItemIndex > -1 then
  begin
    btnWatch.Enabled := True;
  end
  else
  begin
    btnWatch.Enabled := False;
  end;
end;

procedure TForm1.lstFavoritesClick(Sender: TObject);
begin
  CheckFavorites;
end;

procedure TForm1.lstFavoritesDblClick(Sender: TObject);
begin
  if lstFavorites.ItemIndex > -1 then
  begin
    edtChannel.Text := lstFavorites.Items[lstFavorites.ItemIndex];
  end;
end;

procedure TForm1.lstFavoritesDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  DropPosition, StartPosition: Integer;
  DropPoint: TPoint;
begin
  DropPoint.X := X;
  DropPoint.Y := Y;
  with Source as TListBox do
  begin
    StartPosition := ItemAtPos(startingPoint, true);
    DropPosition := ItemAtPos(DropPoint, true);
    if (StartPosition <> -1) and (DropPosition <> -1) then
    begin
      Items.Move(StartPosition, DropPosition);
      SaveFavorites();
    end;
  end;
end;

procedure TForm1.lstFavoritesDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  Accept := Source = lstFavorites;
end;

procedure TForm1.lstFavoritesMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  startingPoint.X := X;
  startingPoint.Y := Y;
end;

procedure TForm1.btnCheckVersionClick(Sender: TObject);
const
  MSG_URL_ERROR = 1;
  MSG_URL_DONE = 2;
begin
  btnCheckVersion.Enabled := False;
  btnCheckVersion.Caption := 'Checking...';

  CreateTask(
    procedure(const task: IOmniTask)
    var
      HttpCli1: THttpCli;
      DataIn: TMemoryStream;
      tmpStr: string;
      hsh: string;
    begin
      hsh := GetFileHash(ParamStr(0));
      hsh := hsh.ToLower;

      DataIn := TMemoryStream.Create;
      HttpCli1 := THttpCli.Create(nil);

      try
        try
          HttpCli1.Agent := 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.154 Safari/537.36';
          HttpCli1.Accept := '*/*';
          HttpCli1.FollowRelocation := True;
          //HttpCli1.Connection := 'Keep-Alive';
          HttpCli1.RequestVer := '1.1';
          HttpCli1.Options := HttpCli1.Options + [httpoEnableContentCoding]; // gzip
          HttpCli1.Timeout := 30;
          HttpCli1.NoCache := True;
          HttpCli1.RcvdStream := DataIn;
          {$IFDEF DEBUG}
          HttpCli1.Proxy     := '127.0.0.1';
          HttpCli1.ProxyPort := '6969';
          {$ENDIF}

          DataIn.Clear;
          HttpCli1.URL := 'http://tards.net/latest.txt';
          try
            HttpCli1.Get;
          except
            on E: Exception do
            begin
              task.Comm.Send(MSG_URL_ERROR, Format('[1] Error: %s', [E.Message]));
              Exit;
            end;
          end;

          tmpStr := DataInToString(DataIn);
          if tmpStr = '' then
          begin
            task.Comm.Send(MSG_URL_ERROR, '[2] Error: result empty');
            Exit;
          end;

          if tmpStr.ToLower = hsh then
            task.Comm.Send(MSG_URL_DONE, false)
          else
            task.Comm.Send(MSG_URL_DONE, true);

        except
          on E: Exception do
          begin
            task.Comm.Send(MSG_URL_ERROR, Format('[3] Error: %s', [E.Message]));
          end;
        end;
      finally
        FreeAndNil(DataIn);
        FreeAndNil(HttpCli1);
      end;
    end
  )
  .OnMessage(
    procedure(const task: IOmniTaskControl; const msg: TOmniMessage)
    begin
      case msg.MsgID of

        MSG_URL_ERROR:
          begin
            btnCheckVersion.Enabled := True;
            btnCheckVersion.Caption := 'Check Version';
            MessageBox(0, PWideChar(msg.MsgData.AsString), 'Tardsplaya', MB_OK or MB_ICONEXCLAMATION);
          end;

        MSG_URL_DONE:
          begin
            btnCheckVersion.Enabled := True;
            btnCheckVersion.Caption := 'Check Version';
            if msg.MsgData.AsBoolean then
              MessageBox(0, 'YAY! There''s a new version.'#13#10'You can download it from tards.net. =))', 'Tardsplaya', MB_OK or MB_ICONINFORMATION)
            else
              MessageBox(0, 'Nop. Nothing new. =(', 'Tardsplaya', MB_OK or MB_ICONEXCLAMATION);
          end;

      end;
    end
  )
  .Unobserved
  .Schedule;
end;

procedure TForm1.btnLoadClick(Sender: TObject);
const
  MSG_URL_ERROR = 1;
  MSG_URL_QUALITY = 2;
  MSG_URL_DONE = 3;
var
 json: ISuperObject;
 channelName: string;
begin
  btnLoad.Enabled := False;
  btnLoad.Caption := 'Loading...';

  btnWatch.Enabled := False;
  lstQuality.Enabled := False;
  lvLog.Clear;

  channelName := edtChannel.Text;
  channelName := channelName.ToLower;

  FreeQualities();

  lstQuality.Enabled := False;

  CreateTask(
    procedure(const task: IOmniTask)
    var
      channel: String;

      HttpCli1: THttpCli;
      DataIn: TMemoryStream;
      tmpStr: string;
      json: ISuperObject;
      strList: TStringList;
      ext: TStringList;
      i: Integer;

      tmpCluster, tmpName, tmpResolution, tmpBitrate, tmpUrl: string;

      quality: TQuality;
    begin
      channel := task.Param['channel'].AsString;

      DataIn := TMemoryStream.Create;
      HttpCli1 := THttpCli.Create(nil);
      strList := TStringList.Create;

      try
        try
          HttpCli1.Agent := 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.154 Safari/537.36';
          HttpCli1.Accept := '*/*';
          HttpCli1.FollowRelocation := True;
          //HttpCli1.Connection := 'Keep-Alive';
          HttpCli1.RequestVer := '1.1';
          HttpCli1.Options := HttpCli1.Options + [httpoEnableContentCoding]; // gzip
          HttpCli1.Timeout := 30;
          HttpCli1.NoCache := True;
          HttpCli1.RcvdStream := DataIn;
          {$IFDEF DEBUG}
          //HttpCli1.Proxy     := '127.0.0.1';
          //HttpCli1.ProxyPort := '6969';
          {$ENDIF}

          DataIn.Clear;
          HttpCli1.URL := 'http://api.twitch.tv/api/channels/' + channel + '/access_token?rnd=' + IntToStr(DateTimeToUNIXTimeFAST(Now()));
          try
            HttpCli1.Get;
          except
            on E: Exception do
            begin
              if (E.Message = 'Not Found') then
              begin
                task.Comm.Send(MSG_URL_ERROR, '[1] Error: Channel not found');
              end
              else
              begin
                task.Comm.Send(MSG_URL_ERROR, Format('[1] Error: %s', [E.Message]));
              end;
              Exit;
            end;
          end;

          tmpStr := DataInToString(DataIn);
          if tmpStr = '' then
          begin
            task.Comm.Send(MSG_URL_ERROR, '[2] Error: access token empty');
            Exit;
          end;

          try
            json := SO(tmpStr);
          except
            on E: Exception do
            begin
              task.Comm.Send(MSG_URL_ERROR, Format('[3] Error: %s', [E.Message]));
              Exit;
            end;
          end;

          DataIn.Clear;
          HttpCli1.URL := 'http://usher.twitch.tv/api/channel/hls/' + channel + '.m3u8?sig=' + UrlEncode(json.AsObject.S['sig']) + '&token=' + UrlEncode(json.AsObject.S['token']) + '&allow_source=true&type=any&private_code=&rnd=' + IntToStr(DateTimeToUNIXTimeFAST(Now()));
          try
            HttpCli1.Get;
          except
            on E: Exception do
            begin
              if (E.Message = 'Not Found') then
              begin
                task.Comm.Send(MSG_URL_ERROR, '[4] Error: Stream not online');
              end
              else
              begin
                task.Comm.Send(MSG_URL_ERROR, Format('[4] Error: %s', [E.Message]));
              end;
              Exit;
            end;
          end;

          strList.Text := DataInToString(DataIn);
          if not strList[0].StartsWith('#EXTM3U') then
          begin
            task.Comm.Send(MSG_URL_ERROR, '[5] Error: no stream found');
            Exit;
          end;

          for i := 0 to strList.Count - 1 do
          begin
            if strList[i].StartsWith('#EXT-X') then
            begin
              if strList[i].StartsWith('#EXT-X-MEDIA:') then
              begin
                ext := SplitExt(strList[i].Replace('#EXT-X-MEDIA:', ''));
                tmpName := ext.Values['NAME'];
                ext.Free;
              end
              else if strList[i].StartsWith('#EXT-X-STREAM-INF:') then
              begin
                ext := SplitExt(strList[i].Replace('#EXT-X-STREAM-INF:', ''));
                tmpResolution := ext.Values['RESOLUTION'];
                tmpBitrate := ext.Values['BANDWIDTH'];
                ext.Free;
              end
              else if strList[i].StartsWith('#EXT-X-TWITCH-INFO:') then
              begin
                ext := SplitExt(strList[i].Replace('#EXT-X-TWITCH-INFO:', ''));
                tmpCluster := ext.Values['CLUSTER'];
                ext.Free;
              end;
            end
            else
            begin
              if strList[i].Contains('://') then
              begin
                tmpUrl := strList[i];

                if tmpResolution <> '' then
                  tmpName := tmpName + ' - ' + tmpResolution + ' ' + IntToStr(StrToInt(tmpBitrate) div 1024) + ' kbps'
                else
                  tmpName := tmpName + ' - ' + IntToStr(StrToInt(tmpBitrate) div 1024) + ' kbps';

                quality := TQuality.Create;
                quality.name := tmpName;
                quality.url := tmpUrl;
                quality.resolution := tmpResolution;
                quality.bitrate := tmpBitrate;

                task.Comm.Send(MSG_URL_QUALITY, quality);
              end;
            end;
          end;

          task.Comm.Send(MSG_URL_DONE, tmpCluster);

        except
          on E: Exception do
          begin
            task.Comm.Send(MSG_URL_ERROR, Format('[6] Error: %s', [E.Message]));
          end;
        end;
      finally
        FreeAndNil(strList);
        FreeAndNil(DataIn);
        FreeAndNil(HttpCli1);
      end;
    end
  )
  .OnMessage(
    procedure(const task: IOmniTaskControl; const msg: TOmniMessage)
    var
      quality: TQuality;
    begin
      case msg.MsgID of

        MSG_URL_ERROR:
          begin
            btnLoad.Enabled := True;
            btnLoad.Caption := '1. Load';
            MessageBox(0, PWideChar(msg.MsgData.AsString), 'Tardsplaya', MB_OK or MB_ICONEXCLAMATION);
          end;

        MSG_URL_QUALITY:
          begin
            quality := TQuality(msg.MsgData.AsObject);
            lstQuality.Items.AddObject(quality.name, quality);
          end;

        MSG_URL_DONE:
          begin
            btnLoad.Enabled := True;
            btnLoad.Caption := '1. Load';
            lblClusterVal.Caption := msg.MsgData.AsString;
            lstQuality.Enabled := True;
          end;

      end;
    end
  )
  .SetParameter('channel', channelName)
  .Unobserved
  .Schedule;

end;

procedure TForm1.btnWatchClick(Sender: TObject);
var
  index: Integer;
begin
  FStreamUrl := TQuality(lstQuality.Items.Objects[lstQuality.ItemIndex]).url;

  edtChannel.Enabled := False;
  btnLoad.Enabled := False;
  lstQuality.Enabled := False;
  btnWatch.Enabled := False;

  index := FStreamUrl.LastIndexOf('/');
  FStreamPath := FStreamUrl.Substring(0, index + 1);

  if not InitWinsock then
  begin
    Exit
  end;
  DoGetVideo;
end;

procedure TForm1.btnAddFavoriteClick(Sender: TObject);
var
  value: string;
begin
  value := InputBox('Add Favorite', 'Channel', '');
  if value <> '' then
  begin
    lstFavorites.Items.Add(value);
    SaveFavorites();
  end;
  CheckFavorites();
end;

procedure TForm1.btnDecSectionsClick(Sender: TObject);
begin
  FSectionCount := FSectionCount - 1;
  if FSectionCount = 1 then
  begin
    btnDecSections.Enabled := False;
  end;
  btnIncSections.Enabled := True;
  lblSectionsVal.Caption := IntToStr(FSectionCount);
  WriteToLog('Section count changed to ' + lblSectionsVal.Caption, False);
end;

procedure TForm1.btnIncSectionsClick(Sender: TObject);
begin
  FSectionCount := FSectionCount + 1;
  if FSectionCount = 4 then
  begin
    btnIncSections.Enabled := False;
  end;
  btnDecSections.Enabled := True;
  lblSectionsVal.Caption := IntToStr(FSectionCount);
  WriteToLog('Section count changed to ' + lblSectionsVal.Caption, False);
end;

procedure TForm1.btnDeleteFavoriteClick(Sender: TObject);
begin
  if lstFavorites.ItemIndex > -1 then
  begin
    if AutoConfirmFavoriteDeletion then
    begin
      DeleteFavorite();
    end
    else
    begin
      if Application.MessageBox
        (PWideChar(Format('You sure you want to delete "%s" from your favorites?',
        [lstFavorites.Items[lstFavorites.ItemIndex]])), 'Delete Favorite',
        MB_YESNO + MB_ICONQUESTION) = IDYES then
      begin
        DeleteFavorite();
      end;
    end;
  end;
  CheckFavorites();
end;

procedure TForm1.btnEditFavoriteClick(Sender: TObject);
var
  value: string;
begin
  if lstFavorites.ItemIndex > -1 then
  begin
    value := InputBox('Edit Favorite', 'Channel',
      lstFavorites.Items[lstFavorites.ItemIndex]);
    if value <> '' then
    begin
      lstFavorites.Items[lstFavorites.ItemIndex] := value;
      SaveFavorites();
    end;
  end;
  CheckFavorites();
end;

procedure TForm1.DoGetVideo;
begin
  FHelloWorker := CreateTask(THelloWorker.Create(FStreamUrl))
  .OnMessage(TaskMessageProc)
  //.SetParameter('ChannelName', channel.ToLower)
  .Unobserved
  .Schedule;
end;

procedure TForm1.Exit1Click(Sender: TObject);
begin
  ExitProcess(0);
end;

procedure SetFormIcons(FormHandle: HWND; SmallIconName, LargeIconName: string);
var
  hIconS, hIconL: Integer;
begin
  hIconS := LoadIcon(hInstance, PChar(SmallIconName));
  if hIconS > 0 then
  begin
    hIconS := SendMessage(FormHandle, WM_SETICON, ICON_SMALL, hIconS);
    if hIconS > 0 then
      DestroyIcon(hIconS);
  end;
  hIconL := LoadIcon(hInstance, PChar(LargeIconName));
  if hIconL > 0 then
  begin
    hIconL := SendMessage(FormHandle, WM_SETICON, ICON_BIG, hIconL);
    if hIconL > 0 then
      DestroyIcon(hIconL);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
  fn: string;
begin
  FStreamUrlQueue := TList<TStreamUrlQueueItem>.Create;
  GlobalOmniThreadPool.MaxExecuting := 12;
  SetFormIcons(Handle, 'MAINICON', 'MAINICON');
  {$IFDEF DEBUG}
    edtChannel.Text := 'end0re';
  {$ENDIF}

  defaultPlayerPath := 'MPC-HC\mpc-hc.exe';
  defaultPlayerCmd := '-';
  PlayerPath := defaultPlayerPath;
  PlayerCmd := defaultPlayerCmd;
  AutoConfirmFavoriteDeletion := False;

  fn := ChangeFileExt(Application.ExeName, '.ini');
  if FileExists(fn) then
  begin
    IniFile := TIniFile.Create(fn);
    try
      PlayerPath := IniFile.ReadString('Settings', 'PlayerPath',
        defaultPlayerPath);
      PlayerCmd := IniFile.ReadString('Settings', 'PlayerCmd',
        defaultPlayerCmd);
      AutoConfirmFavoriteDeletion := IniFile.ReadBool('Settings', 'AutoConfirmFavoriteDeletion', False);
    finally
      IniFile.Free;
    end;
  end;

  FSectionCount := 4;

  fn := ExtractFilePath(ParamStr(0)) + 'favorites.txt';
  if FileExists(fn) then
  begin
    lstFavorites.Items.LoadFromFile(fn);
  end;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  i: Integer;
begin
  TerminateProcess(FPlayerHandle, 0);
  ExitProcess(0);
//  GlobalOmniThreadPool.CancelAll;
//  WSACleanup();
//  for i := 0 to FStreamUrlQueue.Count - 1 do
//    FStreamUrlQueue[i].Free;
//  FStreamUrlQueue.Free;
//  FreeQualities();
end;

{ TExtInf }

function IsNumericString(const inStr: string): Boolean;
var
  i: extended;
begin
  Result := TryStrToFloat(inStr,i);
end;

constructor TExtInf.Create(durationStr, url: string);
var
  spl: string;
  index: Integer;
  fmt: TFormatSettings;
begin
  fmt := TFormatSettings.Create;
  fmt.DecimalSeparator := '.';
  spl := durationStr.Split([','])[0];
  index := AnsiPos('.', spl);
  if index > 0 then
    spl := spl.Substring(0, index + 1);
  Self.duration := StrToFloat(spl, fmt);
  Self.url := url;
end;

procedure TForm1.UpdateQueueText(q:Integer);
begin
  StatusBar1.Panels[0].Text := Format('Chunk Queue: %d', [q]);
end;

procedure DoCheckPlayer(const task: IOmniTask);
var
  FHandle: THandle;
begin
  FHandle := THandle(task.Param['handle']);
  while WaitForSingleObject(FHandle, 50) <> 0 do
  begin

  end;
  ExitProcess(0);
  //task.Comm.Send(MSG_PLAYER_EXIT);

end;

procedure SaveBufferToFile(fileName:string;buffer:Pointer;len:Int64);
var
  fs: TFileStream;
begin
  if FileExists(fileName) then
    DeleteFile(fileName);
  fs := TFileStream.Create(fileName, fmCreate);
  try
    fs.WriteBuffer(buffer, len);
  finally
    fs.Free;
  end;
end;

procedure TForm1.TaskMessageProc(const task: IOmniTaskControl; const msg: TOmniMessage);

  procedure MsgProcCreateDlStreamTask(itm: TStreamUrlQueueItem; startIndex: Int64; endIndex: Int64);
  var
    chunk: TStreamChunk;
  begin
    chunk := TStreamChunk.Create;
    chunk.queueItem := itm;
    chunk.startIndex := startIndex;
    chunk.endIndex := endIndex;

    //WriteToLog(Format('Create part for task %d', [itm.id]));

    CreateTask(DoDlStream)
    .OnMessage(TaskMessageProc)
    .SetParameter('chunk', chunk)
    .Unobserved
    .Schedule;
  end;

  procedure MsgProcCreateWriteStreamTask(itm: TStreamUrlQueueItem);
  begin
    WriteToLog(Format('Begin feeding chunk %d to player', [itm.id]), False);

    CreateTask(WriteStreamToPlayer)
    .OnMessage(TaskMessageProc)
    .SetParameter('item', itm)
    .Unobserved
    .Schedule;
  end;

var
  i: integer;
  qitem: TStreamUrlQueueItem;
  chunk: TStreamChunk;
  chunkSize: Int64;
begin
  //task.Param['ChannelName'].AsString;

  case msg.MsgID of

    MSG_PLAYER_HANDLE:
      begin
        FPlayerHandle := msg.MsgData.AsInt64;
        CreateTask(DoCheckPlayer)
        .OnMessage(TaskMessageProc)
        .SetParameter('handle', FPlayerHandle)
        .Unobserved
        .Schedule;
      end;

    MSG_PLAYER_EXIT:
      begin
        ExitProcess(0);
        WriteToLog('Player was closed?', True);
        FHelloWorker.Stop;
        WriteToLog('[Check new chunk task] stopped', True);
      end;

    MSG_ERROR:
      begin
        WriteToLog(msg.MsgData.AsString, True);
        MessageBox(0, PWideChar(msg.MsgData.AsString), 'Tardsplaya', MB_OK or MB_ICONEXCLAMATION);
        task.Stop;
      end;

    MSG_LOG_ERROR:
      begin
        WriteToLog(msg.MsgData.AsString, True);
      end;

    MSG_STREAM:
      begin
        qitem := TStreamUrlQueueItem.Create;
        qitem.url := FStreamPath + msg.MsgData.AsArray[0].AsString;
        qitem.id := msg.MsgData.AsArray[1].AsInteger;
        qitem.content := nil;
        qitem.contentLength := -1;
        qitem.writtenChunks := 0;
        qitem.totalChunks := FSectionCount;

        // Start download stream
        MsgProcCreateDlStreamTask(qitem, 0, 0);
        FStreamUrlQueue.Add(qitem);
        UpdateQueueText(FStreamUrlQueue.Count);
      end;

    MSG_STREAM_BEGIN_DOWNLOAD:
      begin
        chunk := TStreamChunk(msg.MsgData.AsObject);

        chunkSize := chunk.queueItem.contentLength div chunk.queueItem.totalChunks;

        WriteToLog(Format('Beginning chunk %d download', [chunk.queueItem.id, chunkSize]), False);
        for i := 1 to chunk.queueItem.totalChunks - 1 do
        begin
          MsgProcCreateDlStreamTask(chunk.queueItem, chunkSize * i, (chunkSize * i) + chunkSize);
        end;
      end;

    MSG_STREAM_CHUNK_DOWNLOADED:
      begin
        chunk := TStreamChunk(msg.MsgData.AsObject);
        chunk.queueItem.writtenChunks := chunk.queueItem.writtenChunks + 1;

        WriteToLog(Format('Downloaded part %d/%d from chunk %d', [chunk.queueItem.writtenChunks, chunk.queueItem.totalChunks, chunk.queueItem.id]), False);

        if chunk.queueItem.writtenChunks = chunk.queueItem.totalChunks then
        begin
          // TODO: Write to player

          WriteToLog(Format('All parts from chunk %d downloaded', [chunk.queueItem.id]), False);

          if (not FWritingStream) and (FStreamUrlQueue.IndexOf(chunk.queueItem) = 0) then
            MsgProcCreateWriteStreamTask(chunk.queueItem);

          //SaveBufferToFile('C:\stream.ts', chunk.queueItem.content, chunk.queueItem.contentLength);
          //ShellExecute(0, 'open', 'C:\Program Files (x86)\Free Download Manager\fdm.exe', PWideChar(Format('-fs "%s"', [chunk.queueItem.url])), '',SW_HIDE);
        end;

        chunk.Free;
      end;

    MSG_PLAYER_FINISH_WRITE:
      begin
        FStreamUrlQueue.Delete(0);
        UpdateQueueText(FStreamUrlQueue.Count);
        WriteToLog(Format('Finished feeding chunk %d to player', [msg.MsgData.AsInteger]), False);

        if FStreamUrlQueue.Count = 0 then
          FWritingStream := False
        else
        begin
          if FStreamUrlQueue[0].writtenChunks = FStreamUrlQueue[0].totalChunks then
            MsgProcCreateWriteStreamTask(FStreamUrlQueue[0]);
        end;

      end;

  end;

  //task.ClearTimer(1);
  //task.Stop;
end;

{ THelloWorker }

constructor THelloWorker.Create(const streamUrl: string);
begin
  inherited Create;
  FStreamUrl := streamUrl;

  DataIn := TMemoryStream.Create();
  HttpCli1 := THttpCli.Create(nil);
  strList := TStringList.Create;
  extInfs := TList<TExtInf>.Create;

  HttpCli1.Agent := 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.154 Safari/537.36';
  HttpCli1.Accept := '*/*';
  HttpCli1.FollowRelocation := True;
  HttpCli1.Connection := 'Keep-Alive';
  HttpCli1.RequestVer := '1.1';
  HttpCli1.Options := HttpCli1.Options + [httpoEnableContentCoding]; // gzip
  HttpCli1.Timeout := 10;
  HttpCli1.NoCache := True;
  HttpCli1.RcvdStream := DataIn;
  {$IFDEF DEBUG}
  HttpCli1.Proxy     := '127.0.0.1';
  HttpCli1.ProxyPort := '6969';
  {$ENDIF}

  HttpCli1.URL := FStreamUrl;
end;

destructor THelloWorker.Destroy;
begin
  FreeAndNil(HttpCli1);
  FreeAndNil(extInfs);
  FreeAndNil(strList);
  FreeAndNil(DataIn);

  inherited;
end;

function THelloWorker.Initialize: boolean;
var
  mpchcHandle: THandle;
begin
  Result := true;
  if IsRelativePath(PlayerPath) then
    mpchcHandle := CreateMPCHC(ExtractFilePath(ParamStr(0)) + PlayerPath, PlayerCmd)
  else
    mpchcHandle := CreateMPCHC(PlayerPath, PlayerCmd);

  if mpchcHandle = 0 then
  begin
    task.Comm.Send(MSG_ERROR, 'Error: failed to create player');
    exit;
  end;

  task.Comm.Send(MSG_PLAYER_HANDLE, mpchcHandle);

  FLastTime := 0;

  FExtMediaSequence := 0;

  Task.SetTimer(1, 1, MSG_START_WORK);
end;

procedure THelloWorker.StartWork(var msg: TMessage);
var
  i: Integer;
  TmpExtMediaSequence: Integer;
  errorMsg: string;
  ftime: Int64;
begin
  Task.ClearTimer(1);

  errorMsg := '';
  try
    try
      DataIn.Clear;
      try
        HttpCli1.Get;
      except
        on E: Exception do
        begin
          errorMsg := Format('StartWork() [1] Error: %s', [E.Message]);
          Exit;
        end;
      end;

      strList.Text := DataInToString(DataIn);
      if not strList[0].StartsWith('#EXTM3U') then
      begin
        errorMsg := 'StartWork() [2] Error: no media info found';
        Exit;
      end;

      for i := 0 to strList.Count - 1 do
      begin
        if strList[i].StartsWith('#EXT-X-MEDIA-SEQUENCE:') then
        begin
          TmpExtMediaSequence := StrToInt(strList[i].Substring(22));
          if TmpExtMediaSequence = FExtMediaSequence then
            Exit
          else
            FExtMediaSequence := TmpExtMediaSequence;
        end
        else if strList[i].StartsWith('#EXTINF:') then
        begin
          extInfs.Add( TExtInf.Create(strList[i].Substring(8), strList[i+1]) );
        end;
      end;

      task.Comm.Send(MSG_STREAM, [extInfs[ (extInfs.Count-1) ].url, FExtMediaSequence]);
      //errorMsg := 'stream found';

    except
      on E: Exception do
      begin
        errorMsg := Format('StartWork() [3] Error: %s', [E.Message]);
        Exit;
      end;
    end;

  finally
    for i := 0 to extInfs.Count - 1 do
    begin
      extInfs[i].Free;
    end;
    extInfs.Clear;

    if errorMsg = '' then
    begin
      ftime := MillisecondsBetween(Now, FLastTime);
      FLastTime := Now;
      if ftime > 500 then
      begin
        Task.SetTimer(1, 1, MSG_START_WORK);
      end
      else
      begin
        Task.SetTimer(1, 500 - ftime, MSG_START_WORK);
      end;
    end
    else
    begin
      task.Comm.Send(MSG_LOG_ERROR, errorMsg);
      Task.SetTimer(1, 1, MSG_START_WORK);
    end;
  end;

end;

procedure TForm1.CheckFavorites;
begin
  if lstFavorites.ItemIndex > -1 then
  begin
    btnDeleteFavorite.Enabled := true;
    btnEditFavorite.Enabled := true;
  end
  else
  begin
    btnDeleteFavorite.Enabled := False;
    btnEditFavorite.Enabled := False;
  end;
end;

procedure TForm1.Clear1Click(Sender: TObject);
begin
  lvLog.Clear;
end;

procedure TForm1.SaveFavorites;
begin
  lstFavorites.Items.SaveToFile(ExtractFilePath(ParamStr(0)) + 'favorites.txt');
end;

procedure TForm1.Settings1Click(Sender: TObject);
begin
  Form2 := TForm2.Create(Self);
  try
    Form2.ShowModal();
  finally
    Form2.Release;
  end;
end;

procedure TForm1.DeleteFavorite();
begin
  lstFavorites.Items.Delete(lstFavorites.ItemIndex);
  SaveFavorites();
end;

end.
