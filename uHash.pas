unit uHash;

interface

Uses SysUtils, Classes, SynCrypto;

function GetFileHash(filePath: TFileName):AnsiString;

implementation

function GetFileHash(filePath: TFileName):AnsiString;
var
  ms: TMemoryStream;
  SHA: TSHA1;
  Digest: TSHA1Digest;
begin
  Result := '';

  if not FileExists(filePath) then
  begin
    Exit;
  end;

  ms := TMemoryStream.Create;
  try
    ms.LoadFromFile(filePath);
    SHA.Full(ms.Memory, ms.Size, Digest);
    Result := SHA1DigestToString(Digest);
  finally
    ms.Free;
  end;
end;

end.
