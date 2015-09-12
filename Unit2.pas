unit Unit2;

interface

Uses
  Windows, Winsock, SysUtils, Classes,
  OtlThreadPool, OtlComm, OtlTask, OtlTaskControl,
  OtlParallel, OtlCollections, OtlCommon;


const
  MSG_START_WORK = 1;
  MSG_LOG_ERROR  = 2;
  MSG_ERROR      = 3;
  MSG_STREAM     = 4;
  MSG_STREAM_BEGIN_DOWNLOAD = 6;
  MSG_STREAM_CHUNK_DOWNLOADED = 7;
  MSG_PLAYER_FINISH_WRITE = 8;
  MSG_PLAYER_HANDLE = 9;
  MSG_PLAYER_EXIT = 10;

type
  TStreamUrlQueueItem = class
    url: string;
    id: Integer;
    content: Pointer;
    contentLength: Int64;
    writtenChunks: Byte;
    totalChunks: Byte;
  end;

  TStreamChunk = class
    queueItem: TStreamUrlQueueItem;
    startIndex: Int64;
    endIndex: Int64;
  end;

function InitWinsock:Boolean;
//procedure dlFile(url: string);
procedure DoDlStream(const task: IOmniTask);
function CreateMPCHC(playerPath: string; cmd:string): THandle;
procedure WriteStreamToPlayer(const task: IOmniTask);

implementation

var
  saAttr: SECURITY_ATTRIBUTES;

  g_hChildStd_IN_Rd: THandle;
  g_hChildStd_IN_Wr: THandle;

  g_hInputFile: THandle;

function IsAlpha(s : String) : Boolean;
Var
  e: integer;
  i: integer;
begin
  E := 0;
  for i := 1 to Length(s) do begin
    case s[i] of
      '0'..'9':;
      '.':;
    else
      E := 1;
    end;
  end;
  Result := E <> 0;
end;

function HexToAscii(s: Pointer; len: integer) : string;
Var
  i:Integer;
begin
  Result := '';
  for i := 0 to len-1 do
    result := result + Chr(Ord(PByte(s)[i]));
end;

function InitWinsock:Boolean;
Var
  wVersionRequested: WORD;
  wsaData: TWSAData;
begin
  Result := False;

  wVersionRequested := MAKEWORD(2, 2);
  try
    if WSAStartup(wVersionRequested, wsaData) <> 0 then
    begin
    { Tell the user that we could not find a
      usable WinSock DLL.  }
      MessageBox(0, 'WSAStartup() [1] Error: Could not find a usable WinSock DLL', 'Winsock Error', 0);
      Exit;
    end;

    {  Confirm that the WinSock DLL supports 2.2.
       Note that if the DLL supports versions greater
       than 2.2 in addition to 2.2, it will still return
       2.2 in wVersion since that is the version we
       requested.  }
    if (LOBYTE(wsaData.wVersion) <> 2) OR (HIBYTE(wsaData.wVersion) <> 2) then
    begin
    {  Tell the user that we could not find a usable
       WinSock DLL.  }
      MessageBox(0, 'WSAStartup() [2] Error: Could not find a usable WinSock DLL', 'Winsock Error', 0);
      Exit;
    end;
    {* The WinSock DLL is acceptable. Proceed. *}

    Result := True;
  finally
    if not Result then
      WSACleanup();
  end;
end;

function CreateMPCHC(playerPath: string; cmd: string): THandle;
var
   piProcInfo: PROCESS_INFORMATION;
   siStartInfo: STARTUPINFO;
   rez: Boolean;
begin
  Result := 0;
  // Set the bInheritHandle flag so pipe handles are inherited.
  saAttr.nLength := sizeof(SECURITY_ATTRIBUTES);
  saAttr.bInheritHandle := TRUE;
  saAttr.lpSecurityDescriptor := nil;

  // Create a pipe for the child process's STDIN.
  if not CreatePipe(g_hChildStd_IN_Rd, g_hChildStd_IN_Wr, @saAttr, 0) then
  begin
    Exit;
  end;

  // Ensure the write handle to the pipe for STDIN is not inherited.
  if not SetHandleInformation(g_hChildStd_IN_Wr, HANDLE_FLAG_INHERIT, 0) then
  begin
    Exit;
  end;

  // Create the child process.
  ZeroMemory( @piProcInfo, sizeof(PROCESS_INFORMATION) );

  // Set up members of the STARTUPINFO structure.
  // This structure specifies the STDIN and STDOUT handles for redirection.

  ZeroMemory( @siStartInfo, sizeof(STARTUPINFO) );
  siStartInfo.cb := sizeof(STARTUPINFO);
  siStartInfo.hStdInput := g_hChildStd_IN_Rd;
  siStartInfo.dwFlags := siStartInfo.dwFlags or STARTF_USESTDHANDLES;

  rez := CreateProcess(nil,
      PWideChar(playerPath + ' ' + cmd),     // command line
      nil,          // process security attributes
      nil,          // primary thread security attributes
      TRUE,          // handles are inherited
      0,             // creation flags
      nil,          // use parent's environment
      PWideChar(ExtractFilePath(playerPath)),
      siStartInfo,  // STARTUPINFO pointer
      piProcInfo);  // receives PROCESS_INFORMATION

  // If an error occurs, exit the application.
  if not rez then
  begin
    Exit;
  end
  else
  begin
    // Close handles to the child process and its primary thread.
    // Some applications might keep these handles to monitor the status
    // of the child process, for example.
    Result := piProcInfo.hProcess;
    //CloseHandle(piProcInfo.hProcess);
    CloseHandle(piProcInfo.hThread);
  end;
end;

//procedure WriteToPipe;
//var
//  dwRead, dwWritten: DWORD;
//  chBuf: array[0..BUFSIZE - 1] of byte;
//  bSuccess: Boolean;
//begin
//  bSuccess := False;
//
//  while True do
//  begin
//    bSuccess := ReadFile(g_hInputFile, chBuf, BUFSIZE, dwRead, nil);
//    if ( not bSuccess) or ( dwRead = 0 ) then break;
//
//    bSuccess := WriteFile(g_hChildStd_IN_Wr, chBuf, dwRead, dwWritten, nil);
//    if ( not bSuccess ) then break;
//  end;
//
//// Close the pipe handle so the child process stops reading.
//
// if not CloseHandle(g_hChildStd_IN_Wr) then
//    WriteLn('StdInWr CloseHandle');
//end;


type
  TDownloadItem = class
    url: string;
    buffer: Pointer;
    startIndex: Int64;
    endIndex: Int64;
  end;

procedure WriteStreamToPlayer(const task: IOmniTask);
var
  bSuccess: Boolean;
  dwWritten: DWORD;
  item: TStreamUrlQueueItem;
begin
  item := TStreamUrlQueueItem(task.Param['item'].AsObject);

  bSuccess := False;
  while True do
  begin
    bSuccess := WriteFile(g_hChildStd_IN_Wr, PByte(item.content)[0], item.contentLength, dwWritten, nil);
    if ( not bSuccess ) or (dwWritten >= item.contentLength) then break;
  end;
  FreeMemory(item.content);
  if not bSuccess then
    task.Comm.Send(MSG_LOG_ERROR, Format('Error: Failed feeding chunk %d to the player', [item.id]));
  task.Comm.Send(MSG_PLAYER_FINISH_WRITE, item.id);
  item.Free;
end;

procedure DoDlStream(const task: IOmniTask);
var
  cSocket: TSOCKET;
  sAddr: TSockAddrIn;
  hName: string;
  rHost: PHostEnt;
  hAddr: integer;
  fName: string;
  SendHeaderS : string;
  SendHeaderB : array of byte;
  j: integer;
  recvLen: Integer;
  p: integer;
  tUrl: string;
  RecvHeaderB : packed array[0..8191] of Byte;
  RecvHeaderS : String;
  HeaderEnd   : Integer;

  totalBytes: packed array[0..$FFFF-1] of Byte;
  totalBytesLen: LongInt;

  contentLength: Int64;
  contentWrittenLen: Int64;

  strList: TStringList;

  checkHeaderStartIndex : Integer;

  chunk: TStreamChunk;

  tmpThreadContentLen: Int64;
const
  HTTP_HEADER_END: packed array[0..3] of byte = ($0D, $0A, $0D, $0A);
Label
  beigas;
begin
  chunk := TStreamChunk(task.Param['chunk'].AsObject);

  strList := TStringList.Create;

  ZeroMemory(@cSocket, SizeOf(cSocket));
  tUrl := chunk.queueItem.url;
  p := Pos('://', tUrl);
  if p > 0 then
    delete(tUrl, 1, p + 2);
  p := Pos('/', tUrl);
  hName := Copy(tUrl, 1, p - 1);
  fName := Copy(tUrl, p + 1, Length(tUrl));

  cSocket := Socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (cSocket = INVALID_SOCKET) then
  begin
    task.Comm.Send(MSG_LOG_ERROR, Format('chunk %d [3] Socket() Error: %d', [chunk.queueItem.id, WSAGetLastError]));
    GoTo beigas;
  end;

  ZeroMemory(@sAddr, SizeOf(SockAddr_In));
  sAddr.sin_family := AF_INET;
  sAddr.sin_port   := htons(80);

  if IsAlpha(hName) then
  begin
    rHost := GetHostByName(PAnsiChar(AnsiString(hName)));
  end
  else
  begin
    hAddr := inet_addr(PAnsiChar(AnsiString(hName)));
    rHost := GetHostByAddr(@hAddr, 4, AF_INET);
  end;

  if (WSAGetLastError() <> 0) then
    if (WSAGetLastError() = 11001) then
    begin
      task.Comm.Send(MSG_LOG_ERROR, Format('chunk %d [5] Winsock Error: host not found', [chunk.queueItem.id]) );
      GoTo beigas;
    end
    else
    begin
      task.Comm.Send(MSG_LOG_ERROR, Format('chunk %d [6] Winsock Error: %d', [chunk.queueItem.id, WSAGetLastError]) );
      GoTo beigas;
    end;

  sAddr.sin_addr.s_addr := LongInt(PLongInt(rHost^.h_addr_list^)^);
  if (Connect(cSocket, sAddr, SizeOf(sAddr)) = SOCKET_ERROR) then
  begin
    task.Comm.Send(MSG_LOG_ERROR, Format('chunk %d [7] Connect() Error: %d', [chunk.queueItem.id, WSAGetLastError]) );
    GoTo beigas;
  end;

  if chunk.startIndex <> 0 then
  begin
    SendHeaderS :=
      'GET /' + fName + ' HTTP/1.1' + #13#10 +
      'Host: ' + hName + #13#10 +
      'Connection: close' + #13#10 +
      'Range: bytes=' + IntToStr(chunk.startIndex) + '-' + IntToStr(chunk.endIndex) + #13#10 +
      'User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)' + #13#10#13#10;
  end
  else
  begin
    SendHeaderS :=
      'GET /' + fName + ' HTTP/1.1' + #13#10 +
      'Host: ' + hName + #13#10 +
      'Connection: close' + #13#10 +
      'User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)' + #13#10#13#10;
  end;

  SetLength(SendHeaderB, Length(SendHeaderS));
  for j := 0 to Length(SendHeaderS) - 1 do
  begin
    SendHeaderB[j] := Ord(SendHeaderS[j + 1]);
  end;

  If Send(cSocket, SendHeaderB[0], Length(SendHeaderB), 0) = SOCKET_ERROR then
  begin
    task.Comm.Send(MSG_LOG_ERROR, Format('chunk %d [8] Send() Error: %d', [chunk.queueItem.id, WSAGetLastError]) );
    GoTo beigas;
  end;

  RecvHeaderS := '';
  totalBytesLen := 0;
  HeaderEnd := -1;
  contentLength := -1;
  while true do
  begin
    recvLen := Recv(cSocket, RecvHeaderB, SizeOf(RecvHeaderB), 0);
    if (recvLen = SOCKET_ERROR) OR (recvLen = 0) then
    begin
      task.Comm.Send(MSG_LOG_ERROR, Format('chunk %d [9] Recv() Error: %d', [chunk.queueItem.id, WSAGetLastError]) );
      GoTo beigas;
    end;

    if totalBytesLen > 4 then
      checkHeaderStartIndex := totalBytesLen - 5
    else
      checkHeaderStartIndex := 0;

    Move(RecvHeaderB[0], totalBytes[totalBytesLen], recvLen);
    totalBytesLen := totalBytesLen + recvLen;

    for j := checkHeaderStartIndex to totalBytesLen - 5 do
    begin
      if CompareMem(@HTTP_HEADER_END, @totalBytes[j], 4) then
      begin
        HeaderEnd := j + 4;
        break;
      end;
    end;

    if HeaderEnd > -1 then
    begin
      RecvHeaderS := HexToAscii(@totalBytes, HeaderEnd);
      strList.Text := RecvHeaderS;
      for j := 0 to strList.Count - 1 do
      begin
        if strList[j].ToLower.StartsWith('content-length: ') then
        begin
          contentLength := StrToInt64(strList[j].Substring(16));
          break;
        end;
      end;
      break;
    end;

  end;

  if contentLength > 1 then
  begin
    if chunk.startIndex = 0 then
    begin
      chunk.queueItem.content := GetMemory(contentLength);
      chunk.queueItem.contentLength := contentLength;
      task.Comm.Send(MSG_STREAM_BEGIN_DOWNLOAD, chunk);
      tmpThreadContentLen := contentLength div chunk.queueItem.totalChunks;
    end
    else
    begin
      tmpThreadContentLen := contentLength;
    end;
    contentWrittenLen := totalBytesLen - HeaderEnd;
    Move(totalBytes[HeaderEnd], PByte(chunk.queueItem.content)[chunk.startIndex], contentWrittenLen);
  end
  else
  begin
    task.Comm.Send(MSG_LOG_ERROR, Format('chunk %d [10] content length invalid', [chunk.queueItem.id]) );
  end;

  while true do
  begin
    recvLen := Recv(cSocket, RecvHeaderB, SizeOf(RecvHeaderB), 0);
    if (recvLen = SOCKET_ERROR) then
    begin
      task.Comm.Send(MSG_LOG_ERROR, Format('chunk %d [11] Recv() Error: %d', [chunk.queueItem.id, WSAGetLastError]) );
      GoTo beigas;
    end;

    if (recvLen <= 0) then
    begin
      break
    end;

    if contentWrittenLen + recvLen >= tmpThreadContentLen then
    begin
      Move(RecvHeaderB[0], PByte(chunk.queueItem.content)[chunk.startIndex + contentWrittenLen], tmpThreadContentLen - contentWrittenLen);
      contentWrittenLen := contentWrittenLen + (tmpThreadContentLen - contentWrittenLen);
      break;
    end
    else
    begin
      Move(RecvHeaderB[0], PByte(chunk.queueItem.content)[chunk.startIndex + contentWrittenLen], recvLen);
      contentWrittenLen := contentWrittenLen + recvLen;
    end;
  end;

  if contentWrittenLen <> tmpThreadContentLen  then
  begin
    task.Comm.Send(MSG_LOG_ERROR, Format('chunk %d [12] Error: content length is different from expected', [chunk.queueItem.id]) );
  end;

  task.Comm.Send(MSG_STREAM_CHUNK_DOWNLOADED, chunk);

beigas:
  if cSocket <> 0 then
    CloseSocket(cSocket);
end;

end.
