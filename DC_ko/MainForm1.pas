unit MainForm1;

{$I-}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ComCtrls, IniFiles, Menus, FileCtrl, Math, Xdir, BlankUtils;

const
  maxRecord = 1024 * 512;           // 한꺼번에 비교할 용량 (Test결과 512MB까지는 속도개선효과 있음, 그이상은 거의없음)
type
  TcompareResult = (                // 파일을 비교할 때 일어날 수 있는 모든 경우를 다 생각해 본다
    fileEqual, dataDifferent, sizeDifferent, dateDifferent, attrDifferent, nameDifferent, dosnameDifferent,
    srcNotFound, dstNotFound, srcOpenError, dstOpenError, elseError);
  TcompareSet = set of TcompareResult;

  TFileInfo = record
    FileName: string;               // 파일이름(Full Pathname, 255자 이상도 가능)
    FileNameDos: string[12];        // 도스파일이름
    FileSize: int64;                // 파일크기(2GB 이상도 가능)
    FileDateTime: string[25];       // 파일시각날짜('2003-08-19 14:52:18'처럼)
    FileDateTimeInt: int64;         // 파일시각날짜를 int64로 표현한 값
    FileAttr: string[10];           // 파일속성('A+R-H-S-D-'처럼)
  end;

type
  TMainForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    fileRate: TLabel;               // 파일비교율 0 %
    totalRate: TLabel;              // 전체비교율 0 %
    curFile: TLabel;                // 현재 비교하고 있는 파일
    totalFiles: TLabel;             // 총 Source 파일수:
    totalBytes: TLabel;             // 총 비교한 Byte수:
    SameFile: TLabel;               // 같은 파일수:
    notFound: TLabel;
    runButton: TBitBtn;             // 비교하기
    stopButton: TBitBtn;            // 비교중단
    pauseButton: TBitBtn;           // 일시정지
    tempContButton: TSpeedButton;   // 그림 저장용 버튼
    tempPauseButton: TSpeedButton;  // 그림 저장용 버튼
    optButton: TBitBtn;             // 선택사항
    helpButton: TBitBtn;            // 도움말
    closeButton: TBitBtn;           // 끝내기
    CheckBox1: TCheckBox;           // 하위 디렉토리까지 비교
    ProgressBar1: TProgressBar;
    ProgressBar2: TProgressBar;
    srcPath: TComboBox;
    dstPath: TComboBox;
    Memo1: TMemo;
    fileSizeLabel: TLabel;
    folderSizeLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure runButtonClick(Sender: TObject);
    procedure stopButtonClick(Sender: TObject);
    procedure pauseButtonClick(Sender: TObject);
    procedure optButtonClick(Sender: TObject);
    procedure closeButtonClick(Sender: TObject);
    procedure srcPathKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    stopCompare: boolean;           // 비교를 중지할 수 있게
    pauseCompare: boolean;          // 비교를 일시정지/계속할 수 있게
    Different: integer;             // 서로다른 파일건수
    totalBytes64: int64;            // 비교한 총 바이트수 (totalBytes.tag가 longint(32bit)라서 2G 넘을시 에러나므로 64비트 도입)
    folderKB: integer;              // 폴더크기가 1GB 넘을경우 KB단위로 표시
    srcBuf, dstBuf: array[1..maxRecord] of byte;    // 비교할 버퍼
    recentSrc: TStringList;         // 최근에 열었던 디렉토리 저장
    recentDst: TStringList;         // 최근에 열었던 디렉토리 저장
    srcFileInfo: TFileInfo;         // 현재 비교중인 src 파일에 대한 각종 정보
    dstFileInfo: TFileInfo;         // 현재 비교중인 dst 파일에 대한 각종 정보
    Xdir1: TXdir;
    function Cure (s: string): string;  //C:\File을 C:/File처럼 바꾼다
    procedure ReadOptions;          // INI파일을 읽어들인다
    procedure SaveOptions;          // INI파일로 저장한다
    procedure CheckPause;           // 사용자가 일시정지 버튼을 눌렀는지 검사한다
    function GetSameSizeFile (const src: string; var dst: string): boolean;
    function CompareFile (const src: string; var dst: string): TcompareSet;
    procedure DisplayResult (r: TcompareSet; src, dst: string);
    procedure copyRecent (s:string; srcdst:integer);  // 최근의 10개만 남겨두고 다 지우면서 ComboBox에 복사해 주는 함수
    function getFolderSize (s: string): int64;        // 디렉토리의 모든 파일크기의 합계
    procedure getSrcFileInfo ();                      // src 파일정보 저장
    procedure getDstFileInfo (const dst: string);     // dst 파일정보 저장
  public
    { Public declarations }
    IniFileName: string;            // INI 파일의 이름: ToptForm.FormCreate에서도 참조하므로 public에 놓았다
  end;

var
  MainForm: TMainForm;


implementation

uses OptionForm1;

{$R *.DFM}


function TMainForm.Cure (s: string): string;
begin
  if OptionForm.C10.Checked then Result:= Cure1 (s)
  else Result:= s;
end;


// s를 StringList에 집어넣는다.
procedure TMainForm.copyRecent (s: string; srcdst: integer);
var
  i: integer;
begin
  // recentSrc 및 srcPath에 집어넣고
  if (srcdst=1) then begin
    if (recentSrc.IndexOf(s) >= 0) then exit;
    recentSrc.Add (s);
    if (recentSrc.Count > 10) then recentSrc.Delete (0);
    srcPath.Clear;
    for i:= 1 to recentSrc.Count do srcPath.Items.Add (recentSrc.Strings[i-1]);
    srcPath.Text:= s;
  end
  // recentDst 및 dstPath에 집어넣는다.
  else begin
    if (recentDst.IndexOf(s) >= 0) then exit;
    recentDst.Add (s);
    if (recentDst.Count > 10) then recentDst.Delete (0);
    dstPath.Clear;
    for i:= 1 to recentDst.Count do dstPath.Items.Add (recentDst.Strings[i-1]);
    dstPath.Text:= s;
  end;
end;


procedure TMainForm.ReadOptions;
var
  i: integer;
  s: string;
  IniFile: TIniFile;
begin
  IniFile:= TIniFile.Create (IniFileName);

  // 사용자가 전에 입력한 적이 있는 Source 디렉토리를 ComboBox로 읽어들인다
  srcPath.Text:= IniFile.ReadString ('Source', '현재', '');     // 현재의 디렉토리
  i:= 1;
  repeat
    // 최근 열었던 디렉토리 목록에 추가해 넣는다
    s:= IniFile.ReadString ('Source', '최근 '+inttostr(i), '');
    if s = '' then break;
    recentSrc.Add (s);
    inc (i);
  until false;
  for i:= 1 to recentSrc.Count do srcPath.Items.Add (recentSrc.Strings[i-1]);

  // 사용자가 전에 입력한 적이 있는 Target 디렉토리를 Combo Box로 읽어들인다
  dstPath.Text:= IniFile.ReadString ('Target', '현재', '');     // 현재의 디렉토리
  i:= 1;
  repeat
    // 최근 열었던 디렉토리 목록에 추가해 넣는다
    s:= IniFile.ReadString ('Target', '최근 '+inttostr(i), '');
    if s = '' then break;
    recentDst.Add (s);
    inc (i);
  until false;
  for i:= 1 to recentDst.Count do dstPath.Items.Add (recentDst.Strings[i-1]);

  // 하위 디렉토리를 비교할 건지의 선택상태를 읽어들인다.
  CheckBox1.Checked  := IniFile.ReadBool ('선택사항', '하위 디렉토리 비교', true);
  IniFile.Free;
end;


procedure TMainForm.SaveOptions;
var
    i: integer;
    IniFile: TIniFile;
begin
  try
    IniFile:= TIniFile.Create (IniFileName);

    if OptionForm.C13.Checked then
    begin
      IniFile.WriteBool ('선택사항', '하위 디렉토리 비교',            CheckBox1.Checked);
      IniFile.WriteBool ('선택사항', '파일내용 비교',                 OptionForm.C1.Checked);
      IniFile.WriteBool ('선택사항', '날짜시각 비교',                 OptionForm.C2.Checked);
      IniFile.WriteBool ('선택사항', '파일속성 비교',                 OptionForm.C3.Checked);
      IniFile.WriteBool ('선택사항', '파일이름 대소문자 비교',        OptionForm.C4.Checked);
      IniFile.WriteBool ('선택사항', '도스파일이름 비교',             OptionForm.C5.Checked);
      IniFile.WriteBool ('선택사항', 'Source를 찾을수 없을때 표시',   OptionForm.C6.Checked);
      IniFile.WriteBool ('선택사항', 'Target을 찾을수 없을때 표시',   OptionForm.C7.Checked);
      IniFile.WriteBool ('선택사항', '비교중인 모든 파일 표시하기',   OptionForm.C8.Checked);
      IniFile.WriteBool ('선택사항', '자세하게 표시하기',             OptionForm.C9.Checked);
      IniFile.WriteBool ('선택사항', '\ 대신에 /도 쓸수 있게 하기',   OptionForm.C10.Checked);
      IniFile.WriteBool ('선택사항', '현재파일 비교율 표시',          OptionForm.C11.Checked);
      IniFile.WriteBool ('선택사항', '전체파일 비교율 표시',          OptionForm.C12.Checked);
      IniFile.WriteBool ('선택사항', '같은크기 파일비교',             OptionForm.C14.Checked);
      IniFile.WriteString ('Source', '현재', srcPath.Text);       // 현재의 디렉토리
      IniFile.WriteString ('Target', '현재', dstPath.Text);       // 현재의 디렉토리
      while (recentSrc.Count > 10) do recentSrc.Delete (0);
      while (recentDst.Count > 10) do recentDst.Delete (0);
      for i:= 1 to recentSrc.Count do     // 열었던 디렉토리
        IniFile.WriteString ('Source', '최근 '+inttostr(i), recentSrc.Strings[i-1]);
      for i:= 1 to recentDst.Count do     // 열었던 디렉토리
        IniFile.WriteString ('Target', '최근 '+inttostr(i), recentDst.Strings[i-1]);
    end;

    // 이 항목은 무조건 저장한다
    IniFile.WriteBool ('선택사항', '끝날때 선택사항 저장', OptionForm.C13.Checked);
    IniFile.Free;
  except
  end;
end;


// 사용자가 일시정지 버튼을 눌렀는지 검사한다
procedure TMainForm.CheckPause;
begin
  if pauseCompare then              // 일시정지 버튼을 눌렀으면
  repeat                            // 한번 더 누를 때까지 대기한다
    Application.ProcessMessages;    // 다른 event는 처리해 주면서 대기한다.
    if stopCompare then break;      // 비교중단 버튼을 눌렀다면 나간다.
  until not pauseCompare;
end;


procedure TMainForm.FormCreate(Sender: TObject);
var
  menu: integer;
begin
  // File Open Mode를 Read Only로
  // FileHandle:= FileOpen (filename, fmOpenReadWrite or fmShareDenyNone); 처럼 열 수도 있다.
  FileMode:= fmOpenRead;

  // 사용자가 비교중단 버튼을 누르면 즉시 비교를 중지하도록 하는 변수
  stopCompare:= false;

  // 사용자가 일시정지 버튼을 누르면 즉시 비교를 정지하고 다시한번 더누르면 계속하도록 하는 변수
  pauseCompare:= false;

  // INI 파일 이름: 실행파일과 같은 폴더에 DC.ini로
  IniFileName:= ExtractFilePath(ParamStr(0)) + 'DC.ini';

  // Components 생성
  Xdir1:= TXdir.Create (Self);
  recentSrc:= TStringList.Create;
  recentDst:= TStringList.Create;

  // INI 파일에서 전에 저장해 놓았던 각종 값을 읽어온다
  ReadOptions;
end;


procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveOptions;
  recentSrc.Free;
  recentDst.Free;
  Xdir1.Free;
end;


procedure TMainForm.stopButtonClick(Sender: TObject);
begin
  stopCompare:= true;
  // 혹시 Pause 상태이면 Continue 상태로 되돌린다
  if pauseCompare then pauseButtonClick (Sender);
end;


procedure TMainForm.pauseButtonClick(Sender: TObject);
begin
  pauseCompare:= not pauseCompare;
  if pauseCompare then begin
    pauseButton.Caption:= '(&P)비교계속';
    pauseButton.Glyph:= tempContButton.Glyph;
  end
  else begin
    pauseButton.Caption:= '(&P)일시정지';
    pauseButton.Glyph:= tempPauseButton.Glyph;
  end;
end;


procedure TMainForm.optButtonClick(Sender: TObject);
begin
  OptionForm.ShowModal;
end;


procedure TMainForm.closeButtonClick(Sender: TObject);
begin
  Close;
end;


procedure TMainForm.srcPathKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  if not (Sender as TComboBox).DroppedDown then
  runButtonClick (Sender);
end;


// 디렉토리의 모든 파일크기의 합계를 구한다.
function TMainForm.getFolderSize (s: string): int64;
begin
  // Memo1.Lines.Add (inttostr(DateTimeToTimeStamp(Time).Time));   // 계산전 현재시각(milisecond)
  Xdir1.StartDir:= Cure2(srcPath.Text); // 탐색 시작 디렉토리 지정하고
  Xdir1.Recursive:= CheckBox1.Checked;  // Sub 디렉토리까지 뒤질 건지 지정하고

  result:= 0;
  while Xdir1.Find() do begin           // 뒤져가며
    Application.ProcessMessages;        // 비교중지 버튼을 누르지 않았나 검사할 수 있게 한다
    CheckPause;                         // 일시정지 버튼을 눌렀는지 검사한다
    if stopCompare then exit;           // 비교중지 버튼을 눌렀으면 빠져나간다
    if Xdir1.IsDirectory then continue; // 디렉토리이면 다음파일 찾는다
    // inc (result, bigFileSize(Xdir1.FileName));    // 파일 크기를 누적시킨다: 하드에서 DONG01 전체크기 계산시 30초 걸림
    inc (result, Xdir1.FileSize);       // 파일 크기를 누적시킨다: DONG01 전체크기 계산시 1초도 안걸림 (0.78초)
  end;
  // Memo1.Lines.Add (inttostr(DateTimeToTimeStamp(Time).Time));   // 계산후 현재시각(milisecond)
end;

// 폴더내 같은크기의 파일을 찾아보는 함수
function TMainForm.GetSameSizeFile (const src: string; var dst: string): boolean;
var
  sr: TSearchRec;

function getFSize64 (h,l: cardinal): int64;
begin
  result:= h;
  result:= result shl 32 + l;
end;

begin
  result:= false;

  if FindFirst (ExtractFileDir(dst)+'\*', $27, sr) = 0 then
  begin
    if (srcFileInfo.FileSize = getFSize64(sr.FindData.nFileSizeHigh, sr.FindData.nFileSizeLow))
    then result:= true
    else while (FindNext(sr) = 0) do
    if (srcFileInfo.FileSize = getFSize64(sr.FindData.nFileSizeHigh, sr.FindData.nFileSizeLow)) then
    begin
      result:= true;
      break;
    end;
    FindClose (sr);
  end;
  if (result = true) then dst:= ExtractFileDir(dst) + '\' + sr.Name;
end;







/////////////////////////////////////////////////////////////////////////////////////////////////
// 여기서부터 파일정보 저장하는 함수
//

// 파일날짜 변환
function FileTimeToString (FileTime: TFileTime): string;
var
  i: integer;
  LFileTime: TFileTime;
  SystemTime: TSystemTime;
begin
  if (not FileTimeToLocalFileTime(FileTime, LFileTime)) then result:= '날짜변환 에러' else
  if (not FileTimeToSystemTime (LFileTime, SystemTime)) then result:= '날짜변환 에러' else
  begin
    result:= Format ('%04d-%02d-%02d %02d:%02d:%02d', [SystemTime.wYear, SystemTime.wMonth, SystemTime.wDay, SystemTime.wHour, SystemTime.wMinute, SystemTime.wSecond]);
    for i:= 1 to length(result) do if result[i]=' ' then result[i]:= '0';
    result[11]:= ' ';
  end;
end;

// 파일속성을 integer로 가져와서 보기좋게 string으로 바꾸어 리턴하는 함수
function FileAttrToString (attr: integer): string;
begin
  {
  faReadOnly  $00000001   Read-only files
  faHidden    $00000002   Hidden files
  faSysFile   $00000004   System files
  faVolumeID  $00000008   Volume ID files
  faDirectory $00000010   Directory files
  faArchive   $00000020   Archive files
  faAnyFile   $0000003F   Any file
  }
  result:= 'A-R-H-S-D-';
  if attr and faArchive   > 0 then result[ 2]:= '+';
  if attr and faReadOnly  > 0 then result[ 4]:= '+';
  if attr and faHidden    > 0 then result[ 6]:= '+';
  if attr and faSysFile   > 0 then result[ 8]:= '+';
  if attr and faDirectory > 0 then result[10]:= '+';
end;

// 현재 비교하는 src 파일의 정보를 저장해 둔다.
// src 정보는 Xdir.SearchRec에 정보가 다 있다.
procedure TMainForm.getSrcFileInfo();
begin
  // src 파일 정보를 저장해 놓는다.
  fillchar (srcFileInfo, sizeof(TFileInfo), 0);
  srcFileInfo.FileName:= Xdir1.SearchRec.Name;
  srcFileInfo.FileNameDos:= Xdir1.SearchRec.FindData.cAlternateFileName;
  // 간혹 가다 이 도스파일 이름인 cAlternateFileName이 공백(nil)일 경우가 있는데, 그럴 때에는 긴파일 이름인 Name을 사용하도록 한다.
  if (srcFileInfo.FileNameDos = '') then srcFileInfo.FileNameDos:= srcFileInfo.FileName;
  srcFileInfo.FileSize:= Xdir1.FileSize;
  srcFileInfo.FileDateTime:= FileTimeToString (Xdir1.SearchRec.FindData.ftLastWriteTime);
  srcFileInfo.FileDateTimeInt:= Xdir1.SearchRec.FindData.ftLastWriteTime.dwHighDateTime;
  srcFileInfo.FileDateTimeInt:= srcFileInfo.FileDateTimeInt shl 32 + Xdir1.SearchRec.FindData.ftLastWriteTime.dwLowDateTime;
  srcFileInfo.FileAttr:= FileAttrToString (Xdir1.SearchRec.Attr);
end;

// 현재 비교하는 dst 파일의 정보를 FindFirst()하여 가져와 저장해 둔다.
procedure TMainForm.getDstFileInfo (const dst: string);
var
  sr: TSearchRec;
begin
  // dst 파일 정보를 저장해 놓는다.
  fillchar (dstFileInfo, sizeof(TFileInfo), 0);
  if (FindFirst(dst,faAnyFile,sr) <> 0) then exit;
  dstFileInfo.FileName:= sr.Name;
  dstFileInfo.FileNameDos:= sr.FindData.cAlternateFileName;
  if (dstFileInfo.FileNameDos = '') then dstFileInfo.FileNameDos:= dstFileInfo.FileName;
  dstFileInfo.FileSize:= sr.FindData.nFileSizeHigh;
  dstFileInfo.FileSize:= dstFileInfo.FileSize shl 32 + sr.FindData.nFileSizeLow;
  dstFileInfo.FileDateTime:= FileTimeToString (sr.FindData.ftLastWriteTime);
  dstFileInfo.FileDateTimeInt:= sr.FindData.ftLastWriteTime.dwHighDateTime;
  dstFileInfo.FileDateTimeInt:= dstFileInfo.FileDateTimeInt shl 32 + sr.FindData.ftLastWriteTime.dwLowDateTime;
  dstFileInfo.FileAttr:= FileAttrToString (sr.Attr);
  FindClose (sr);
end;







/////////////////////////////////////////////////////////////////////////////////////////////////
// 실제로 파일을 비교하는 함수로서, src, dst는 파일의 Full Pathname으로 넘어온다
//
function TMainForm.CompareFile (const src: string; var dst: string): TcompareSet;
label
  ExitPoint;
var
  srcFile, dstFile: TFileStream;                // 파일 변수
  numRead1, numRead2: integer;                  // 실제로 읽은 바이트수
  i: integer;
  totalTemp64: int64;                           // 임시로 저장: 지금까지 비교한 총바이트수
  KB: integer;                                  // 파일크기가 1GB넘으면 1024
  sr: TSearchRec;
  re: boolean;
begin
  result:= [fileEqual];                         // 리턴값 = 두 파일이 같다

  // 현재 비교되고 있는 파일 및 전체상황을 표시해 준다.
  if OptionForm.C11.Checked then                // 선택사항 - 현재파일 비교율
  curFile.Caption:= '파일: ' + toRelativePath(Cure1(src),srcPath.Text);   //현재 비교하고 있는 파일을 화면에 표시

  totalFiles.tag:= totalFiles.tag + 1;          // 총 Source 파일수를 표시
  totalFiles.Caption:= '총 Source 파일수: ' + inttostr3(totalFiles.tag);

  // Source 파일이 존재하는지 검사를 한다.
  if (not File_Exists(src)) then begin          // 파일이 존재하지 않는다면
    result:= result - [fileEqual];              // 리턴값 = 두 파일이 다르다
    if (DirectoryExists(ExtractFileDir(src)))   // 디렉토리가 존재하면
    then result:= result + [srcNotFound]        // 리턴값 = Source 파일이 없다
    else result:= result + [srcOpenError];      // 리턴값 = Source 파일을 열 수 없다
    exit;
  end;

  // Src파일 정보를 읽어놓는다. 나중에 DisplayResult()에서도 사용된다.
  getSrcFileInfo();                             // srcFileInfo에 저장됨

  // Target 파일이 존재하는지 검사를 한다.
  if (not File_Exists(dst)) then begin          // 파일이 존재하지 않는다면
    if OptionForm.C14.Checked
    then re:= GetSameSizeFile (src, dst)        // 같은폴더내 같은크기 파일 찾아본다. dst는 새파일이름 가져옴
    else re:= false;                            // 옵션이 지정안되어 있으면 못찾은 걸로 간주하여 아래 빠져나감

    if (not re) then begin                      // 결과가 없으면
      result:= result - [fileEqual];            // 리턴값 = 두 파일이 다르다
      if (DirectoryExists(ExtractFileDir(dst))) // 디렉토리가 존재하면
      then result:= result + [dstNotFound]      // 리턴값 = Target 파일이 없다
      else result:= result + [dstOpenError];    // 리턴값 = Target 파일을 열 수 없다
      exit;
    end;
  end;

  // Dst파일 정보를 읽어놓는다. 나중에 DisplayResult()에서도 사용된다.
  getDstFileInfo (dst);                         // dstFileInfo에 저장됨
  // 실제의 Dst파일 이름으로 바꿔준다. 대소문자가 다를경우 나중에 DisplayResult()에서 src와 다르게 출력하기 위함
  dst:= ExtractFilePath(dst) + dstFileInfo.FileName;

  // 파일속성 비교
  // 왜 여기서 하느냐 하면, src는 파일인데 dst는 같은 이름의 디렉토리일 수가 있기 때문에 그것 처리하기 위함
  if OptionForm.C3.Checked then                 // 선택사항 - 파일속성 비교
  if (srcFileInfo.FileAttr <> dstFileInfo.FileAttr) then begin    //파일속성이 다르면
    result:= result - [fileEqual];              // 리턴값 = 두 파일이 다르다
    result:= result + [attrDifferent];          // 리턴값 = 파일의 속성이 다르다
  end;

  // 파일의 날짜/시각 비교
  if OptionForm.C2.Checked then                 // 선택사항 - 날짜/시각 비교
  // 파일날짜가 다르면: 절대값 차이가 3초이하이면 같은걸로 간주 (초과시 다른걸로 간주)
  if abs(srcFileInfo.FileDateTimeInt-dstFileInfo.FileDateTimeInt) > 30000000 then begin
    result:= result - [fileEqual];              // 리턴값 = 두 파일이 다르다
    result:= result + [dateDifferent];          // 리턴값 = 파일의 날짜/시각이 다르다
  end;

  // 선택사항 - (도스)파일이름 비교 -> 파일의 이름만을 비교한다. 디렉토리 경로는 대소문자 비교를 하지 않는다.
  if OptionForm.C4.Checked or OptionForm.C5.Checked then begin    // 선택사항 - 파일이름 비교 또는 도스파일이름 비교
    if (OptionForm.C4.Checked) then             // 선택사항 - 파일이름 비교
    if (srcFileInfo.FileName <> dstFileInfo.FileName) then begin  // 파일 이름이 다르면
      result:= result - [fileEqual];            // 리턴값 = 두 파일이 다르다
      result:= result + [nameDifferent];        // 리턴값 = 파일의 이름이 다르다
    end;

    if (OptionForm.C5.Checked) then             // 선택사항 - 도스파일이름 비교
    if (srcFileInfo.FileNameDos <> dstFileInfo.FileNameDos) then begin
      result:= result - [fileEqual];            // 리턴값 = 두 파일이 다르다
      result:= result + [dosnameDifferent];     // 리턴값 = 도스파일이름이 다르다
    end;
  end;

  // 옵션에 관계없이 두 파일의 크기가 다르면 무조건 다른 파일이므로 빠져나간다
  if (srcFileInfo.FileSize <> dstFileInfo.FileSize) then begin
    result:= result - [fileEqual];              // 리턴값 = 두 파일이 다르다
    result:= result + [sizeDifferent];          // 리턴값 = 파일크기가 다르다
    exit;                                       // 빠져나간다
  end;


  /////////////////////////////////////////////////////////////////////////////////////////////////
  // 여기서부터는 파일내용 비교와 관련된 곳으로서, 선택사항에 파일내용 비교가 check되어 있지 않으면 여기서 나가면 된다.
  //
  if not OptionForm.C1.Checked then exit;       // 선택사항 - 파일내용 비교

  // ProgressBar1의 100 % 값을 지정한다
  if (srcFileInfo.FileSize >= 1024*1024*1024) then KB:= 1024 else KB:= 1;

  // 파일내용을 비교하기 전에, 옵션에 따라 두 파일이 다르다면 내용비교 자체를 하지 않고 빠져나가도록 한다.
  if not (fileEqual in result) then exit;

  // 여기까지 와서 둘다 0바이트라면 같은 파일이다.
  if (srcFileInfo.FileSize = 0) then begin      // 둘다 0바이트짜리 파일이라면
    result:= result + [fileEqual];              // 리턴값 = 두 파일이 같다
    exit;                                       // 빠져나간다
  end;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // 파일을 열고 이제 파일을 건드리기 시작한다
  //
  try
    // Source 파일을 연다
    srcFile:= TFileStream.Create(src, fmOpenRead);
    srcFile.Seek(0, soFromBeginning);
  except                                        // src 파일을 열 수 없다면
    result:= result - [fileEqual];              // 리턴값 = 두 파일이 다르다
    result:= result + [srcOpenError];           // 리턴값 = Source 파일을 열 수 없다
    exit;                                       // 빠져나간다
  end;

  try
    // Target 파일을 연다
    dstFile:= TFileStream.Create(dst, fmOpenRead);
    dstFile.Seek(0, soFromBeginning);
  except                                        // dst 파일을 열 수 없다면
    result:= result - [fileEqual];              // 리턴값 = 두 파일이 다르다
    result:= result + [dstOpenError];           // 리턴값 = Target 파일을 열 수 없다
    srcFile.Free;                               // src 파일을 닫는다
    exit;                                       // 빠져나간다
  end;

  if OptionForm.C11.Checked then begin          // 선택사항 - 현재파일 비교율
    ProgressBar1.Position:= 0;                  // ProgressBar1의 표시를 지운다 (0%)
    ProgressBar1.Max:= srcFileInfo.FileSize div KB; // 현재파일의 크기를 ProgressBar의 100%값으로 지정
    fileSizeLabel.Caption:= '['+inttoKB (srcFileInfo.FileSize)+']'; // 현재파일의 크기 표시
    fileRate.Caption:= inttostr(floor(ProgressBar1.Position/ProgressBar1.Max*100)) + '%';
  end;
  if OptionForm.C12.Checked then                // 선택사항 - 전체파일 비교율
    totalTemp64:= totalBytes64;                 // ProgressBar2의 현재 위치를 저장해 둔다 (중간에 빠져나가면 파일 크기만큼 증가시키기 위함)

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // 가장 중요한 부분으로서, 파일의 내용을 비교하는 곳이다
  //
  if OptionForm.C1.Checked then                 // 선택사항 - 파일내용 비교
  repeat                                        // 파일의 내용을 비교한다
    Application.ProcessMessages;                // 화면을 갱신하고 이벤트를 검사할 틈을 준다
    CheckPause;                                 // 일시정지/비교중단 버튼을 눌렀는지 검사한다
    if stopCompare then break;                  // 사용자가 비교중단 버튼을 눌렀으면 빠져나간다

    // maxRecord만큼 읽는다. numRead는 실제로 읽은 값이다
    numRead1:= srcFile.Read(srcBuf, maxRecord);
    numRead2:= dstFile.Read(dstBuf, maxRecord);
    // 읽은 바이트가 없으면 eof까지 온 것이므로 빠져나간다
    if (numRead1 = 0) or (numRead2 = 0) then break;

    if OptionForm.C11.Checked then begin        // 선택사항 - 현재파일 비교율
      // 파일을 몇 % 읽었는지 ProgressBar와 Label로 표시한다
      ProgressBar1.Position:= ProgressBar1.Position + (numRead1 div KB);
      fileRate.Caption:= inttostr(floor(ProgressBar1.Position/ProgressBar1.Max*100)) + '%';
    end;
    if OptionForm.C12.Checked then begin        // 선택사항 - 전체파일 비교율
      ProgressBar2.Position:= ProgressBar2.Position + (numRead1 div folderKB);
      totalRate.Caption:= inttostr(floor(ProgressBar2.Position/ProgressBar2.Max*100)) + '%';
    end;

    // 읽은 바이트수만큼 비교를 한다. 처음 비교할 때에는 i의 개입이 없이 한꺼번에 이진 비교를 하도록 한다
    if CompareMem (@srcBuf, @dstBuf, numRead1) = false then   // 차이점이 발견되면
    begin
      for i:= 1 to numRead1 do                  // 읽은 바이트수만큼 다시 비교를 하여 어디서 달랐는지 확인한다
      if (srcBuf[i] <> dstBuf[i]) then begin    // 차이점이 난 곳에서 for문을 빠져나오게 된다
        if OptionForm.C12.Checked then begin    // 선택사항 - 전체파일 비교율
          // 총파일 진행률은 여기서 그냥 빠져나갈 경우 최종적으로 100%에 못미치기 때문에
          // 이렇게 아까 저장해 두었던 값에다가 파일크기만큼 더해줘야 한다.
          ProgressBar2.Position:= (totalTemp64 + srcFileInfo.FileSize) div folderKB;
          totalRate.Caption:= inttostr(floor(ProgressBar2.Position/ProgressBar2.Max*100)) + '%';
        end;
        break;
      end;
      totalBytes64:= totalBytes64 + i-1;        // 총 비교한 Source 파일의 바이트수 총합계를 누적한다
      totalBytes.Caption:= '총 비교한  Byte수: ' + inttostr3(totalBytes64);
      result:= result - [fileEqual];            // 리턴값 = 두 파일이 다르다
      result:= result + [dataDifferent];        // 리턴값 = 파일내용이 다르다
      break;                                    // 빠져나간다
    end;                                        // 읽은 바이트수만큼의 비교를 다했다

    totalBytes64:= totalBytes64 + numRead1;     // 총 비교한 Byte수
    totalBytes.Caption:= '총 비교한  Byte수: ' + inttostr3(totalBytes64);
  until false;

  srcFile.Free;      // 파일을 닫는다
  dstFile.Free;      // 파일을 닫는다
end;


/////////////////////////////////////////////////////////////////////////////////////////////////
// 파일 비교의 결과를 분석하여 화면에 적당히 표시해 준다
//
procedure TMainForm.DisplayResult (r: TcompareSet; src, dst: string);
var
  s: string;
begin
  // C:\Dir\FileName 을 C:/Dir/FileName 처럼 고친다
  src:= Cure1 (src);
  dst:= Cure1 (dst);

  // 결과출력시 상대경로만 출력하도록 한다.
  src:= toRelativePath (src, srcPath.Text);
  dst:= toRelativePath (dst, dstPath.Text);

  // 같은파일 처리
  if (fileEqual in r) then begin            // 두 파일이 같으면
    SameFile.tag:= SameFile.tag + 1;        // 같은파일 건수를 ++시킨다
    SameFile.Caption:= '같은 파일수: ' + inttostr3(SameFile.tag);
    if OptionForm.C8.Checked then           // 선택사항 - 현재파일 표시
      if OptionForm.C9.Checked              // 선택사항 - 자세히 표시
      then Memo1.Lines.Add ('차이점 없음: ' + src + ' 〓 ' + dst)
      else Memo1.Lines.Add ('차이점 없음: ' + src);
    exit;                                   // 더이상 볼것 없으므로 나간다
  end
  else Different:= Different + 1;           // 파일이 같지 않으면 갯수++

  // 비교중 문제점이 발견되었다면 메모장에 그 내용을 출력한다.
  // 문제점이 몇 개든간에 한 파일당 메모장 한 줄을 차지하는 것을 원칙으로 한다.
  s:= '';                                   // 메모장에 출력할 문자열

  // 파일의 날짜/시각이 서로 다르다면
  if (dateDifferent in r) then s:= '파일 시간이';

  // 파일의 속성이 서로 다르다면
  if (attrDifferent in r) then
  if (s='') then s:= '파일 속성이'
  else s:= '시간,속성이';

  // 파일의 크기가 서로 다르다면
  if (sizeDifferent in r) then
  if (s='') then s:= '파일 크기가'
  else begin
    if (s[5]<>',') then delete (s, 1, 5);   // 맨앞에 '파일 ' 자를 지운다
    delete (s, length(s)-1, 2);             // 주격조사 '이'를 지운다
    s:= s + ',크기가';                      // 끝에 ',크기가'를 끼워넣는다
  end;

  // 파일의 대소문자 이름이 서로 다르다면
  if (nameDifferent in r) then
  if (s='') then s:= '파일 이름이'
  else begin
    if (s[5]<>',') then delete (s, 1, 5);   // 맨앞에 '파일 ' 자를 지운다
    delete (s, length(s)-1, 2);             // 주격조사를 지운다
    s:= s + ',이름이';                      // 끝에 ',이름이'를 끼워넣는다
  end;

  // 도스파일이름이 서로 다르다면
  if (dosnameDifferent in r) then
  if (s='') then s:= '도스파일 이름이'
  else begin
    if (s[5]<>',') then delete (s, 1, 5);   // 맨앞에 '파일 ' 자를 지운다
    delete (s, length(s)-1, 2);             // 주격조사를 지운다
    s:= s + ',도스파일이름이';              // 끝에 ',도스파일이름이'를 끼워넣는다
  end;

  // 파일의 내용이 서로 다르다면
  if (dataDifferent in r) then
  if (s='') then s:= '파일 내용이'
  else begin
    if (s[5]<>',') then delete (s, 1, 5);   // 맨앞에 '파일 ' 자를 지운다
    delete (s, length(s)-1, 2);             // 주격조사를 지운다
    s:= s + ',내용이';                      // 끝에 ',내용이'를 끼워넣는다
  end;

  if (s > '') then
  if (not OptionForm.C9.Checked) then       // 선택사항 - 자세하게 표시 아니면
    Memo1.Lines.Add (s + ' 다름: ' + src)
  else begin                                // 선택사항 - 자세하게 표시
    Memo1.Lines.Add (s + ' 다름: ' + src +' ≠ ' + dst);
    if (r <> [dataDifferent]) then begin    // 내용만 다를 경우에는 표시하지 않는다.
      s:= '   파일1: ';                     // Source 파일의 사항을 자세히 표시
      if (dateDifferent in r   ) then s:= s + srcFileInfo.FileDateTime;
      if (s[length(s)] <> ' '  ) then s:= s + '   ';
      if (attrDifferent in r   ) then s:= s + srcFileInfo.FileAttr;
      if (s[length(s)] <> ' '  ) then s:= s + '   ';
      if (sizeDifferent in r   ) then s:= s + inttostr3(srcFileInfo.FileSize) + 'B';
      if (s[length(s)] <> ' '  ) then s:= s + '   ';
      if (nameDifferent in r   ) then s:= s + srcFileInfo.FileName;
      if (s[length(s)] <> ' '  ) then s:= s + '   ';
      if (dosnameDifferent in r) then s:= s + srcFileInfo.FileNameDos;
      Memo1.Lines.Add (s);

      s:= '   파일2: ';                     // Target 파일의 사항을 자세히 표시
      if (dateDifferent in r   ) then s:= s + dstFileInfo.FileDateTime;
      if (s[length(s)] <> ' '  ) then s:= s + '   ';
      if (attrDifferent in r   ) then s:= s + dstFileInfo.FileAttr;
      if (s[length(s)] <> ' '  ) then s:= s + '   ';
      if (sizeDifferent in r   ) then s:= s + inttostr3(dstFileInfo.FileSize) + 'B';
      if (s[length(s)] <> ' '  ) then s:= s + '   ';
      if (nameDifferent in r   ) then s:= s + dstFileInfo.FileName;
      if (s[length(s)] <> ' '  ) then s:= s + '   ';
      if (dosnameDifferent in r) then s:= s + dstFileInfo.FileNameDos;
      Memo1.Lines.Add (s);
    end;
  end;

  // 선택사항 - Source에러 표시 -> Source 파일을 여는 데 실패했다면 (두 가지 경우가 있다)
  if (OptionForm.C6.Checked) then           // 선택사항 - Source 에러 표시
  if (srcNotFound  in r) then Memo1.Lines.Add ('파일이 없음: ' + src) else // 내가 이 프로그램을 잘못 짜지 않는 한 이런 경우는 절대 없을 것이다
  if (srcOpenError in r) then Memo1.Lines.Add ('파일을 열 수가 없음: ' + src);

  // 선택사항 - Target에러 표시 -> Target 파일을 여는 데 실패했다면 (두 가지 경우가 있다)
  if (OptionForm.C7.Checked) then
  if (dstNotFound in r) or (dstOpenError in r) then begin
    notFound.tag:= notFound.tag + 1;
    notFound.Caption:= 'Target 파일 없음: ' + inttostr3(notFound.tag);
    if (dstNotFound  in r) then Memo1.Lines.Add ('파일이 없음: ' + dst) else
    if (dstOpenError in r) then Memo1.Lines.Add ('파일을 열 수가 없음: ' + dst);
  end;

  // 그외 알수없는 에러 발생시
  if (elseError in r) then Memo1.Lines.Add (src + ' 파일 비교중 알수없는 에러');
end;


/////////////////////////////////////////////////////////////////////////////////////////////////
// 사용자가 파일을 비교하라는 명령을 내렸을 때 (버튼을 눌렀을 때) 실행되는 함수
//
procedure TMainForm.runButtonClick(Sender: TObject);
var
  dt: string;
  src, dst: string;                         // 파일 이름을 저장하는 곳
  srcFullPath, dstFullPath: string;         // 사용자가 입력한 src와 dst의 Full Path를 저장하는 곳
  compareSet: TcompareSet;                  // CompareFile 함수 호출 결과값을 받아오는 변수
  folderSize: int64;                        // 비교할 source디렉토리의 총크기
begin
  Memo1.Clear;                              // 메모장을 지운다

  if (srcPath.Text = '') then begin
    Memo1.Lines.Add ('Source 디렉토리를 입력하세요');
    srcPath.SetFocus; exit;                 // 빠져나간다
  end;

  if (dstPath.Text = '') then begin
    Memo1.Lines.Add ('Target 디렉토리를 입력하세요');
    dstPath.SetFocus; exit;                 // 빠져나간다
  end;

  // 사용자가 간략히 입력하더라도 그 디렉토리의 Full Path를 알아내어 처리한다
  srcFullPath:= ExpandFileName (srcPath.Text);
  dstFullPath:= ExpandFileName (dstPath.Text);

  // 이렇게 Full Path를 구해도 루트 디렉토리인 경우에는 C:\처럼 되고 그외에는 C:\Dir 처럼 되므로 끝에 모두 \를 붙여 통일시킨다
  if (srcFullPath[length(srcFullPath)] <> '\') then srcFullPath:= srcFullPath + '\';
  if (dstFullPath[length(dstFullPath)] <> '\') then dstFullPath:= dstFullPath + '\';

  // 비교할 두 디렉토리가 같으면 비교를 하지 않는다
  if (UpperCase(srcPath.Text) = UpperCase(dstPath.Text))
  or (UpperCase(srcFullPath ) = UpperCase(dstFullPath )) then begin
    Memo1.Lines.Add ('비교할 두 디렉토리의 위치가 같습니다');
    Memo1.Lines.Add ('Source 디렉토리 = ' + Cure1(srcFullPath));
    Memo1.Lines.Add ('Target 디렉토리 = ' + Cure1(dstFullPath));
    srcPath.SetFocus; exit;                 // 빠져나간다
  end;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // 별다른 지적사항이 없으면 이제 비교를 시작한다
  //
  // 사용자가 입력한 현재의 디렉토리를 Combo Box의 List에 추가한다
  copyRecent (srcPath.Text, 1);
  copyRecent (dstPath.Text, 2);

  Caption:= '비교중...';                    // Title바의 글자를 지정하고
  Application.Title:= Caption;              // Minimize했을 때의 Title 글자도 지정한다

  Label1.Enabled:= false;                   // Source Path Label 불가
  Label2.Enabled:= false;                   // Target Path Label 불가
  srcPath.Enabled:= false;                  // Source Path 변경 불가
  dstPath.Enabled:= false;                  // Source Path 변경 불가
  runButton.Enabled:= false;                // 비교하기 버튼 불가
  stopButton.Enabled:= true;                // 비교중단 버튼 가능
  pauseButton.Enabled:= true;               // 일시정지 버튼 가능
  optButton.Enabled:= false;                // 선택사항 버튼 불가
  closeButton.Enabled:= false;              // 끝 내 기 버튼 불가
  CheckBox1.Enabled:= false;                // 서브디렉토리 뒤지기 Check 불가

  Different:= 0;                            // 서로다른 파일갯수
  totalFiles.tag:= 0;                       // 지금까지 읽은 Source 파일의 총 갯수를 저장하는 변수
  totalFiles.Caption:= '총 Source 파일수: ' + inttostr3(totalFiles.tag);
  totalBytes64:= 0;                         // 지금까지 비교한 총 Byte수를 저장하는 변수
  totalBytes.Caption:= '총 비교한  Byte수: ' + inttostr3(totalBytes64);
  SameFile.tag := 0;                        // 같은파일 갯수를 저장하는 변수
  SameFile.Caption := '같은 파일수: ' + inttostr3(SameFile.tag);
  notFound.tag  := 0;                       // Source파일은 있는데 Target파일이 없는 것의 갯수를 저장하는 변수
  notFound.Caption  := 'Target 파일 없음: ' + inttostr3(notFound.tag);

  stopCompare := false;
  pauseCompare:= false;
  folderKB:= 1;
  folderSizeLabel.Caption:= '';

  if OptionForm.C12.Checked then            // 선택사항 - 전체파일 비교율
  if OptionForm.C1.Checked then             // 선택사항 - 파일내용 비교 -> Source 디렉토리의 파일 크기의 총합을 구한다
  begin
    Memo1.Lines.Add (Cure1(srcPath.Text) + ' 디렉토리...');
    folderSize:= getFolderSize(srcFullPath);
    // 1GB가 넘을경우 KB단위로 표시해 준다. 안그러면 range overflow 에러남.
    if (folderSize >= 1024*1024*1024) then folderKB:= 1024 else folderKB:= 1;
    ProgressBar2.Max:= folderSize div folderKB;
    // 방금 계산한 디렉토리 크기를 위에 표시한 메시지의 끝에다가 덧붙여 준다
    // Memo1.Lines.Add ('▶ 디렉토리 크기: ' + inttoKB(folderSize) + ' (' + inttostr3(folderSize) + ' 바이트)'#13#10);
    Memo1.Lines.Strings[Memo1.Lines.Count-1]:= Cure1(srcPath.Text) + ' 디렉토리: ' + inttoKB(folderSize) + ' (' + inttostr3(folderSize) + ' 바이트)';
    // ProgressBar 뒤에도 표시해 준다.
    folderSizeLabel.Caption:= '[' + inttoKB(folderSize) + ']';
  end;

  DatetimeToString (dt, 'hh:nn:ss', now);
  Memo1.Lines.Add ('['+dt+'] 디렉토리 비교를 하고 있는 중입니다...');
  Xdir1.StartDir:= Cure2(srcFullPath);      // 탐색 시작 디렉토리 지정하고
  Xdir1.Recursive:= CheckBox1.Checked;      // Sub 디렉토리까지 뒤질 건지 지정을 한다

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // 지금까지는 비교를 위한 준비사항이었고, 본격적인 비교작업은 이제부터 한다
  //
  CheckPause;                               // 일시정지 버튼을 눌렀는지 검사한다
  if not stopCompare then                   // 비교중지 버튼을 눌렀으면 검사하지 않는다
  while Xdir1.Find() do begin               // 파일을 하나씩 찾는다
    Application.ProcessMessages;            // 사용자가 무슨 조작을 했는지 Event 검사를 할 틈을 준다
    CheckPause;                             // 일시정지 버튼을 눌렀는지 검사한다
    if stopCompare then break;              // 사용자가 비교중단 버튼을 눌렀으면 빠져나간다
    if Xdir1.IsDirectory then continue;     // 파일이 아니고 디렉토리라면 다음것 계속 탐색

    src:= Xdir1.FileName;                   // Source 파일 - S:\Dir1\FileName을 만듬
    dst:= src;                              // Target 파일 - 앞대가리를 바꿔야 한다

    // dst = S:\Dir1\SubDir\FileName 에서 사용자가 입력한 Source Path의 Full Path인 S:\Dir1\ 를 삭제한다.
    // 삭제 결과는 dst = FileName 또는 SubDir\FileName이다
    Delete (dst, 1, length(srcFullPath));

    // 위 결과의 앞에다가 사용자가 입력한 Target Path의 Full Path인 T:\ 또는 T:\Dir2\ 를 붙인다.
    dst:= dstFullPath + dst;

    // Target Directory가 존재하는지 검사하여, 존재하지 않는다면 건너뛴다.
    // 이는 Xdir 컴포넌트를 사용하지 않고 자체 파일탐색 기능을 했을 경우 가능한 것임.
    // 다음에 구현할 것
    // if (not DirectoryExists (ExtractFileDir(dst)));

    // -------------- 핵 심 함 수 호 출 -----------------------------
    // 파일을 비교한다. src, dst는 파일의 Full Pathname이다.
    compareSet:= CompareFile (src, dst);

    // 비교결과를 화면에 표시해 준다
    DisplayResult (compareSet, src, dst);
  end;

  // 선택사항 - Source 파일을 찾을 수 없으면 일러주기
  CheckPause;                               // 일시정지 버튼을 눌렀는지 검사한다
  if not stopCompare then                   // 비교중지 버튼을 눌렀으면 검사하지 않는다
  if (OptionForm.C6.Checked) then begin
    Memo1.Lines.Add ('');
    Memo1.Lines.Add ('※ Source 디렉토리에는 없는데 Target 디렉토리에만 있는 파일:');
    Xdir1.StartDir:= Cure2(dstFullPath);    // 탐색 시작 디렉토리 지정하고
    Memo1.tag:= 0;                          // Target 디렉토리에만 있는 파일이 아직은 없다
    while Xdir1.Find do begin               // Target 디렉토리를 뒤진다
      Application.ProcessMessages;          // 사용자가 무슨 조작을 했는지 Event 검사를 할 틈을 준다
      CheckPause;                           // 일시정지 버튼을 눌렀는지 검사한다
      if stopCompare then break;            // 사용자가 비교중단 버튼을 눌렀으면 빠져나간다
      if Xdir1.IsDirectory then continue;   // 파일이 아니고 디렉토리라면 다음것 계속 탐색

      dst:= Xdir1.FileName;                 // Target 파일 - T:\Dir1\FileName을 만듬
      src:= dst;                            // Source 파일 - 앞대가리를 바꿔야 한다
      Delete (src, 1, length(dstFullPath)); // T:\Dir1\를 삭제
      src:= srcFullPath + src;              // S:\Dir2\를 붙인다

      if not File_Exists(src) then begin    // Source 파일이 없으면
        if Memo1.tag=0 then Memo1.tag:= 1;  // Target 디렉토리에만 있는 파일이 하나 이상 생겼다
        Memo1.Lines.Add (toRelativePath(Cure1(dst),dstPath.Text));  // 그 파일을 출력한다
      end;
    end;    // while문 끝 - Target 디렉토리를 다 뒤졌다
    // Target 디렉토리에만 있는 파일이 있었으면 Tag를 원래대로 복귀해 준다
    if Memo1.tag = 1 then Memo1.tag:= 0
    // Target 디렉토리에만 있는 파일이 하나도 없으면 없다고 출력해 준다
    else Memo1.Lines.Strings[Memo1.Lines.Count-1]:= Memo1.Lines.Strings[Memo1.Lines.Count-1] + ' 없음';
  end;                                      // OptionForm.C6.Checked 처리 끝

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // 모든 비교작업이 끝났으므로 각종 설정을 원래대로 해준다
  //
  Application.ProcessMessages;          // 마지막 100% 상태를 한번 그려줄수 있게한다
  if stopCompare then Xdir1.Stop        // Find 도중에 중단되면 한번 호출해 줘야 한다.
  else curFile.Caption:= '파일:';       // 정상종료시에는 파일표시를 지운다 (강제로 끝냈으면 냅둔다)
  Caption:= '디렉토리 비교기';          // Title바의 글자를 지정하고
  Application.Title:= Caption;          // Minimize했을 때의 Title 글자도 지정한다

  Label1.Enabled:= true;                // Source Path Label 가능
  Label2.Enabled:= true;                // Target Path Label 가능
  srcPath.Enabled:= true;               // Source Path 변경 가능
  dstPath.Enabled:= true;               // Source Path 변경 가능
  runButton.Enabled:= true;             // 비교하기 버튼 가능
  stopButton.Enabled:= false;           // 비교중단 버튼 불가
  // 혹시 Pause 상태이면 Continue 상태로 되돌린다
  if pauseCompare then pauseButtonClick (Sender);
  pauseButton.Enabled:= false;          // 일시정지 버튼 불가
  optButton.Enabled:= true;             // 선택사항 버튼 가능
  closeButton.Enabled:= true;           // 끝 내 기 버튼 가능
  CheckBox1.Enabled:= true;             // 서브디렉토리 뒤지기 Check 가능

  if OptionForm.C11.Checked then begin  // 선택사항 - 현재파일 비교율
    ProgressBar1.Position:= 0;          // ProgressBar1의 표시를 지운다
    fileRate.Caption:= '0%';            // 파일 비교율을 0%로 한다
    fileSizeLabel.Caption:= '';         // 파일크기 표시를 지운다.
  end;
  if OptionForm.C12.Checked then begin  // 선택사항 - 전체파일 비교율
    ProgressBar2.Position:= 0;          // ProgressBar1의 표시를 지운다
    totalRate.Caption:= '0%';           // 전체파일 비교율도 0%로 한다
    folderSizeLabel.Caption:= '';       // 폴더크기 표시를 지운다.
  end;

  // 메모장에 작업을 끝냈다는 메시지를 추가한다
  if Memo1.Lines.Count > 0 then Memo1.Lines.Add ('');
  DatetimeToString (dt, 'hh:nn:ss', now);
  if (stopCompare = false)
  then Memo1.Lines.Add ('['+dt+'] 디렉토리 비교를 끝냈습니다.')
  else Memo1.Lines.Add ('['+dt+'] 디렉토리 비교를 중단했습니다.');

  // 선택사항 - 전체파일 비교율 표시를 하지 않도록 해 놓았으면, 모든 비교가 다 끝난 후에 전체 파일 갯수와 바이트수를 표시해 준다
  if not OptionForm.C12.Checked then
    Memo1.Lines.Add ('총 ' + inttostr3(totalFiles.tag) + ' 개 파일, ' + inttostr3(totalBytes64) + ' 바이트를 비교했습니다');

  // 정상적으로 모든 파일을 비교하여 차이점이 발견되지 않았다면 축하 메시지를 하나 던져준다.
  if (stopCompare = false) then
  if (Different = 0) then Memo1.Lines.Add ('두 디렉토리에 차이점이 없습니다.');

  // Memo1.SetFocus;                    // 커서를 메모장으로 옮긴다
  srcPath.SetFocus;                     // 커서를 Source Path 입력창으로 옮긴다
end;

end.

