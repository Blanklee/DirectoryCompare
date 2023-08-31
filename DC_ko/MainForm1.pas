unit MainForm1;

{$I-}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ComCtrls, IniFiles, Menus, FileCtrl, Math, Xdir, BlankUtils;

const
  maxRecord = 1024 * 512;           // �Ѳ����� ���� �뷮 (Test��� 512MB������ �ӵ�����ȿ�� ����, ���̻��� ���Ǿ���)
type
  TcompareResult = (                // ������ ���� �� �Ͼ �� �ִ� ��� ��츦 �� ������ ����
    fileEqual, dataDifferent, sizeDifferent, dateDifferent, attrDifferent, nameDifferent, dosnameDifferent,
    srcNotFound, dstNotFound, srcOpenError, dstOpenError, elseError);
  TcompareSet = set of TcompareResult;

  TFileInfo = record
    FileName: string;               // �����̸�(Full Pathname, 255�� �̻� ����)
    FileNameDos: string[12];        // ���������̸�
    FileSize: int64;                // ����ũ��(2GB �̻� ����)
    FileDateTime: string[25];       // ���Ͻð���¥('2003-08-19 14:52:18'ó��)
    FileDateTimeInt: int64;         // ���Ͻð���¥�� int64�� ǥ���� ��
    FileAttr: string[10];           // ���ϼӼ�('A+R-H-S-D-'ó��)
  end;

type
  TMainForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    fileRate: TLabel;               // ���Ϻ��� 0 %
    totalRate: TLabel;              // ��ü���� 0 %
    curFile: TLabel;                // ���� ���ϰ� �ִ� ����
    totalFiles: TLabel;             // �� Source ���ϼ�:
    totalBytes: TLabel;             // �� ���� Byte��:
    SameFile: TLabel;               // ���� ���ϼ�:
    notFound: TLabel;
    runButton: TBitBtn;             // ���ϱ�
    stopButton: TBitBtn;            // ���ߴ�
    pauseButton: TBitBtn;           // �Ͻ�����
    tempContButton: TSpeedButton;   // �׸� ����� ��ư
    tempPauseButton: TSpeedButton;  // �׸� ����� ��ư
    optButton: TBitBtn;             // ���û���
    helpButton: TBitBtn;            // ����
    closeButton: TBitBtn;           // ������
    CheckBox1: TCheckBox;           // ���� ���丮���� ��
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
    stopCompare: boolean;           // �񱳸� ������ �� �ְ�
    pauseCompare: boolean;          // �񱳸� �Ͻ�����/����� �� �ְ�
    Different: integer;             // ���δٸ� ���ϰǼ�
    totalBytes64: int64;            // ���� �� ����Ʈ�� (totalBytes.tag�� longint(32bit)�� 2G ������ �������Ƿ� 64��Ʈ ����)
    folderKB: integer;              // ����ũ�Ⱑ 1GB ������� KB������ ǥ��
    srcBuf, dstBuf: array[1..maxRecord] of byte;    // ���� ����
    recentSrc: TStringList;         // �ֱٿ� ������ ���丮 ����
    recentDst: TStringList;         // �ֱٿ� ������ ���丮 ����
    srcFileInfo: TFileInfo;         // ���� ������ src ���Ͽ� ���� ���� ����
    dstFileInfo: TFileInfo;         // ���� ������ dst ���Ͽ� ���� ���� ����
    Xdir1: TXdir;
    function Cure (s: string): string;  //C:\File�� C:/Fileó�� �ٲ۴�
    procedure ReadOptions;          // INI������ �о���δ�
    procedure SaveOptions;          // INI���Ϸ� �����Ѵ�
    procedure CheckPause;           // ����ڰ� �Ͻ����� ��ư�� �������� �˻��Ѵ�
    function GetSameSizeFile (const src: string; var dst: string): boolean;
    function CompareFile (const src: string; var dst: string): TcompareSet;
    procedure DisplayResult (r: TcompareSet; src, dst: string);
    procedure copyRecent (s:string; srcdst:integer);  // �ֱ��� 10���� ���ܵΰ� �� ����鼭 ComboBox�� ������ �ִ� �Լ�
    function getFolderSize (s: string): int64;        // ���丮�� ��� ����ũ���� �հ�
    procedure getSrcFileInfo ();                      // src �������� ����
    procedure getDstFileInfo (const dst: string);     // dst �������� ����
  public
    { Public declarations }
    IniFileName: string;            // INI ������ �̸�: ToptForm.FormCreate������ �����ϹǷ� public�� ���Ҵ�
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


// s�� StringList�� ����ִ´�.
procedure TMainForm.copyRecent (s: string; srcdst: integer);
var
  i: integer;
begin
  // recentSrc �� srcPath�� ����ְ�
  if (srcdst=1) then begin
    if (recentSrc.IndexOf(s) >= 0) then exit;
    recentSrc.Add (s);
    if (recentSrc.Count > 10) then recentSrc.Delete (0);
    srcPath.Clear;
    for i:= 1 to recentSrc.Count do srcPath.Items.Add (recentSrc.Strings[i-1]);
    srcPath.Text:= s;
  end
  // recentDst �� dstPath�� ����ִ´�.
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

  // ����ڰ� ���� �Է��� ���� �ִ� Source ���丮�� ComboBox�� �о���δ�
  srcPath.Text:= IniFile.ReadString ('Source', '����', '');     // ������ ���丮
  i:= 1;
  repeat
    // �ֱ� ������ ���丮 ��Ͽ� �߰��� �ִ´�
    s:= IniFile.ReadString ('Source', '�ֱ� '+inttostr(i), '');
    if s = '' then break;
    recentSrc.Add (s);
    inc (i);
  until false;
  for i:= 1 to recentSrc.Count do srcPath.Items.Add (recentSrc.Strings[i-1]);

  // ����ڰ� ���� �Է��� ���� �ִ� Target ���丮�� Combo Box�� �о���δ�
  dstPath.Text:= IniFile.ReadString ('Target', '����', '');     // ������ ���丮
  i:= 1;
  repeat
    // �ֱ� ������ ���丮 ��Ͽ� �߰��� �ִ´�
    s:= IniFile.ReadString ('Target', '�ֱ� '+inttostr(i), '');
    if s = '' then break;
    recentDst.Add (s);
    inc (i);
  until false;
  for i:= 1 to recentDst.Count do dstPath.Items.Add (recentDst.Strings[i-1]);

  // ���� ���丮�� ���� ������ ���û��¸� �о���δ�.
  CheckBox1.Checked  := IniFile.ReadBool ('���û���', '���� ���丮 ��', true);
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
      IniFile.WriteBool ('���û���', '���� ���丮 ��',            CheckBox1.Checked);
      IniFile.WriteBool ('���û���', '���ϳ��� ��',                 OptionForm.C1.Checked);
      IniFile.WriteBool ('���û���', '��¥�ð� ��',                 OptionForm.C2.Checked);
      IniFile.WriteBool ('���û���', '���ϼӼ� ��',                 OptionForm.C3.Checked);
      IniFile.WriteBool ('���û���', '�����̸� ��ҹ��� ��',        OptionForm.C4.Checked);
      IniFile.WriteBool ('���û���', '���������̸� ��',             OptionForm.C5.Checked);
      IniFile.WriteBool ('���û���', 'Source�� ã���� ������ ǥ��',   OptionForm.C6.Checked);
      IniFile.WriteBool ('���û���', 'Target�� ã���� ������ ǥ��',   OptionForm.C7.Checked);
      IniFile.WriteBool ('���û���', '������ ��� ���� ǥ���ϱ�',   OptionForm.C8.Checked);
      IniFile.WriteBool ('���û���', '�ڼ��ϰ� ǥ���ϱ�',             OptionForm.C9.Checked);
      IniFile.WriteBool ('���û���', '\ ��ſ� /�� ���� �ְ� �ϱ�',   OptionForm.C10.Checked);
      IniFile.WriteBool ('���û���', '�������� ���� ǥ��',          OptionForm.C11.Checked);
      IniFile.WriteBool ('���û���', '��ü���� ���� ǥ��',          OptionForm.C12.Checked);
      IniFile.WriteBool ('���û���', '����ũ�� ���Ϻ�',             OptionForm.C14.Checked);
      IniFile.WriteString ('Source', '����', srcPath.Text);       // ������ ���丮
      IniFile.WriteString ('Target', '����', dstPath.Text);       // ������ ���丮
      while (recentSrc.Count > 10) do recentSrc.Delete (0);
      while (recentDst.Count > 10) do recentDst.Delete (0);
      for i:= 1 to recentSrc.Count do     // ������ ���丮
        IniFile.WriteString ('Source', '�ֱ� '+inttostr(i), recentSrc.Strings[i-1]);
      for i:= 1 to recentDst.Count do     // ������ ���丮
        IniFile.WriteString ('Target', '�ֱ� '+inttostr(i), recentDst.Strings[i-1]);
    end;

    // �� �׸��� ������ �����Ѵ�
    IniFile.WriteBool ('���û���', '������ ���û��� ����', OptionForm.C13.Checked);
    IniFile.Free;
  except
  end;
end;


// ����ڰ� �Ͻ����� ��ư�� �������� �˻��Ѵ�
procedure TMainForm.CheckPause;
begin
  if pauseCompare then              // �Ͻ����� ��ư�� ��������
  repeat                            // �ѹ� �� ���� ������ ����Ѵ�
    Application.ProcessMessages;    // �ٸ� event�� ó���� �ָ鼭 ����Ѵ�.
    if stopCompare then break;      // ���ߴ� ��ư�� �����ٸ� ������.
  until not pauseCompare;
end;


procedure TMainForm.FormCreate(Sender: TObject);
var
  menu: integer;
begin
  // File Open Mode�� Read Only��
  // FileHandle:= FileOpen (filename, fmOpenReadWrite or fmShareDenyNone); ó�� �� ���� �ִ�.
  FileMode:= fmOpenRead;

  // ����ڰ� ���ߴ� ��ư�� ������ ��� �񱳸� �����ϵ��� �ϴ� ����
  stopCompare:= false;

  // ����ڰ� �Ͻ����� ��ư�� ������ ��� �񱳸� �����ϰ� �ٽ��ѹ� �������� ����ϵ��� �ϴ� ����
  pauseCompare:= false;

  // INI ���� �̸�: �������ϰ� ���� ������ DC.ini��
  IniFileName:= ExtractFilePath(ParamStr(0)) + 'DC.ini';

  // Components ����
  Xdir1:= TXdir.Create (Self);
  recentSrc:= TStringList.Create;
  recentDst:= TStringList.Create;

  // INI ���Ͽ��� ���� ������ ���Ҵ� ���� ���� �о�´�
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
  // Ȥ�� Pause �����̸� Continue ���·� �ǵ�����
  if pauseCompare then pauseButtonClick (Sender);
end;


procedure TMainForm.pauseButtonClick(Sender: TObject);
begin
  pauseCompare:= not pauseCompare;
  if pauseCompare then begin
    pauseButton.Caption:= '(&P)�񱳰��';
    pauseButton.Glyph:= tempContButton.Glyph;
  end
  else begin
    pauseButton.Caption:= '(&P)�Ͻ�����';
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


// ���丮�� ��� ����ũ���� �հ踦 ���Ѵ�.
function TMainForm.getFolderSize (s: string): int64;
begin
  // Memo1.Lines.Add (inttostr(DateTimeToTimeStamp(Time).Time));   // ����� ����ð�(milisecond)
  Xdir1.StartDir:= Cure2(srcPath.Text); // Ž�� ���� ���丮 �����ϰ�
  Xdir1.Recursive:= CheckBox1.Checked;  // Sub ���丮���� ���� ���� �����ϰ�

  result:= 0;
  while Xdir1.Find() do begin           // ��������
    Application.ProcessMessages;        // ������ ��ư�� ������ �ʾҳ� �˻��� �� �ְ� �Ѵ�
    CheckPause;                         // �Ͻ����� ��ư�� �������� �˻��Ѵ�
    if stopCompare then exit;           // ������ ��ư�� �������� ����������
    if Xdir1.IsDirectory then continue; // ���丮�̸� �������� ã�´�
    // inc (result, bigFileSize(Xdir1.FileName));    // ���� ũ�⸦ ������Ų��: �ϵ忡�� DONG01 ��üũ�� ���� 30�� �ɸ�
    inc (result, Xdir1.FileSize);       // ���� ũ�⸦ ������Ų��: DONG01 ��üũ�� ���� 1�ʵ� �Ȱɸ� (0.78��)
  end;
  // Memo1.Lines.Add (inttostr(DateTimeToTimeStamp(Time).Time));   // ����� ����ð�(milisecond)
end;

// ������ ����ũ���� ������ ã�ƺ��� �Լ�
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
// ���⼭���� �������� �����ϴ� �Լ�
//

// ���ϳ�¥ ��ȯ
function FileTimeToString (FileTime: TFileTime): string;
var
  i: integer;
  LFileTime: TFileTime;
  SystemTime: TSystemTime;
begin
  if (not FileTimeToLocalFileTime(FileTime, LFileTime)) then result:= '��¥��ȯ ����' else
  if (not FileTimeToSystemTime (LFileTime, SystemTime)) then result:= '��¥��ȯ ����' else
  begin
    result:= Format ('%04d-%02d-%02d %02d:%02d:%02d', [SystemTime.wYear, SystemTime.wMonth, SystemTime.wDay, SystemTime.wHour, SystemTime.wMinute, SystemTime.wSecond]);
    for i:= 1 to length(result) do if result[i]=' ' then result[i]:= '0';
    result[11]:= ' ';
  end;
end;

// ���ϼӼ��� integer�� �����ͼ� �������� string���� �ٲپ� �����ϴ� �Լ�
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

// ���� ���ϴ� src ������ ������ ������ �д�.
// src ������ Xdir.SearchRec�� ������ �� �ִ�.
procedure TMainForm.getSrcFileInfo();
begin
  // src ���� ������ ������ ���´�.
  fillchar (srcFileInfo, sizeof(TFileInfo), 0);
  srcFileInfo.FileName:= Xdir1.SearchRec.Name;
  srcFileInfo.FileNameDos:= Xdir1.SearchRec.FindData.cAlternateFileName;
  // ��Ȥ ���� �� �������� �̸��� cAlternateFileName�� ����(nil)�� ��찡 �ִµ�, �׷� ������ ������ �̸��� Name�� ����ϵ��� �Ѵ�.
  if (srcFileInfo.FileNameDos = '') then srcFileInfo.FileNameDos:= srcFileInfo.FileName;
  srcFileInfo.FileSize:= Xdir1.FileSize;
  srcFileInfo.FileDateTime:= FileTimeToString (Xdir1.SearchRec.FindData.ftLastWriteTime);
  srcFileInfo.FileDateTimeInt:= Xdir1.SearchRec.FindData.ftLastWriteTime.dwHighDateTime;
  srcFileInfo.FileDateTimeInt:= srcFileInfo.FileDateTimeInt shl 32 + Xdir1.SearchRec.FindData.ftLastWriteTime.dwLowDateTime;
  srcFileInfo.FileAttr:= FileAttrToString (Xdir1.SearchRec.Attr);
end;

// ���� ���ϴ� dst ������ ������ FindFirst()�Ͽ� ������ ������ �д�.
procedure TMainForm.getDstFileInfo (const dst: string);
var
  sr: TSearchRec;
begin
  // dst ���� ������ ������ ���´�.
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
// ������ ������ ���ϴ� �Լ��μ�, src, dst�� ������ Full Pathname���� �Ѿ�´�
//
function TMainForm.CompareFile (const src: string; var dst: string): TcompareSet;
label
  ExitPoint;
var
  srcFile, dstFile: TFileStream;                // ���� ����
  numRead1, numRead2: integer;                  // ������ ���� ����Ʈ��
  i: integer;
  totalTemp64: int64;                           // �ӽ÷� ����: ���ݱ��� ���� �ѹ���Ʈ��
  KB: integer;                                  // ����ũ�Ⱑ 1GB������ 1024
  sr: TSearchRec;
  re: boolean;
begin
  result:= [fileEqual];                         // ���ϰ� = �� ������ ����

  // ���� �񱳵ǰ� �ִ� ���� �� ��ü��Ȳ�� ǥ���� �ش�.
  if OptionForm.C11.Checked then                // ���û��� - �������� ����
  curFile.Caption:= '����: ' + toRelativePath(Cure1(src),srcPath.Text);   //���� ���ϰ� �ִ� ������ ȭ�鿡 ǥ��

  totalFiles.tag:= totalFiles.tag + 1;          // �� Source ���ϼ��� ǥ��
  totalFiles.Caption:= '�� Source ���ϼ�: ' + inttostr3(totalFiles.tag);

  // Source ������ �����ϴ��� �˻縦 �Ѵ�.
  if (not File_Exists(src)) then begin          // ������ �������� �ʴ´ٸ�
    result:= result - [fileEqual];              // ���ϰ� = �� ������ �ٸ���
    if (DirectoryExists(ExtractFileDir(src)))   // ���丮�� �����ϸ�
    then result:= result + [srcNotFound]        // ���ϰ� = Source ������ ����
    else result:= result + [srcOpenError];      // ���ϰ� = Source ������ �� �� ����
    exit;
  end;

  // Src���� ������ �о���´�. ���߿� DisplayResult()������ ���ȴ�.
  getSrcFileInfo();                             // srcFileInfo�� �����

  // Target ������ �����ϴ��� �˻縦 �Ѵ�.
  if (not File_Exists(dst)) then begin          // ������ �������� �ʴ´ٸ�
    if OptionForm.C14.Checked
    then re:= GetSameSizeFile (src, dst)        // ���������� ����ũ�� ���� ã�ƺ���. dst�� �������̸� ������
    else re:= false;                            // �ɼ��� �����ȵǾ� ������ ��ã�� �ɷ� �����Ͽ� �Ʒ� ��������

    if (not re) then begin                      // ����� ������
      result:= result - [fileEqual];            // ���ϰ� = �� ������ �ٸ���
      if (DirectoryExists(ExtractFileDir(dst))) // ���丮�� �����ϸ�
      then result:= result + [dstNotFound]      // ���ϰ� = Target ������ ����
      else result:= result + [dstOpenError];    // ���ϰ� = Target ������ �� �� ����
      exit;
    end;
  end;

  // Dst���� ������ �о���´�. ���߿� DisplayResult()������ ���ȴ�.
  getDstFileInfo (dst);                         // dstFileInfo�� �����
  // ������ Dst���� �̸����� �ٲ��ش�. ��ҹ��ڰ� �ٸ���� ���߿� DisplayResult()���� src�� �ٸ��� ����ϱ� ����
  dst:= ExtractFilePath(dst) + dstFileInfo.FileName;

  // ���ϼӼ� ��
  // �� ���⼭ �ϴ��� �ϸ�, src�� �����ε� dst�� ���� �̸��� ���丮�� ���� �ֱ� ������ �װ� ó���ϱ� ����
  if OptionForm.C3.Checked then                 // ���û��� - ���ϼӼ� ��
  if (srcFileInfo.FileAttr <> dstFileInfo.FileAttr) then begin    //���ϼӼ��� �ٸ���
    result:= result - [fileEqual];              // ���ϰ� = �� ������ �ٸ���
    result:= result + [attrDifferent];          // ���ϰ� = ������ �Ӽ��� �ٸ���
  end;

  // ������ ��¥/�ð� ��
  if OptionForm.C2.Checked then                 // ���û��� - ��¥/�ð� ��
  // ���ϳ�¥�� �ٸ���: ���밪 ���̰� 3�������̸� �����ɷ� ���� (�ʰ��� �ٸ��ɷ� ����)
  if abs(srcFileInfo.FileDateTimeInt-dstFileInfo.FileDateTimeInt) > 30000000 then begin
    result:= result - [fileEqual];              // ���ϰ� = �� ������ �ٸ���
    result:= result + [dateDifferent];          // ���ϰ� = ������ ��¥/�ð��� �ٸ���
  end;

  // ���û��� - (����)�����̸� �� -> ������ �̸����� ���Ѵ�. ���丮 ��δ� ��ҹ��� �񱳸� ���� �ʴ´�.
  if OptionForm.C4.Checked or OptionForm.C5.Checked then begin    // ���û��� - �����̸� �� �Ǵ� ���������̸� ��
    if (OptionForm.C4.Checked) then             // ���û��� - �����̸� ��
    if (srcFileInfo.FileName <> dstFileInfo.FileName) then begin  // ���� �̸��� �ٸ���
      result:= result - [fileEqual];            // ���ϰ� = �� ������ �ٸ���
      result:= result + [nameDifferent];        // ���ϰ� = ������ �̸��� �ٸ���
    end;

    if (OptionForm.C5.Checked) then             // ���û��� - ���������̸� ��
    if (srcFileInfo.FileNameDos <> dstFileInfo.FileNameDos) then begin
      result:= result - [fileEqual];            // ���ϰ� = �� ������ �ٸ���
      result:= result + [dosnameDifferent];     // ���ϰ� = ���������̸��� �ٸ���
    end;
  end;

  // �ɼǿ� ������� �� ������ ũ�Ⱑ �ٸ��� ������ �ٸ� �����̹Ƿ� ����������
  if (srcFileInfo.FileSize <> dstFileInfo.FileSize) then begin
    result:= result - [fileEqual];              // ���ϰ� = �� ������ �ٸ���
    result:= result + [sizeDifferent];          // ���ϰ� = ����ũ�Ⱑ �ٸ���
    exit;                                       // ����������
  end;


  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ���⼭���ʹ� ���ϳ��� �񱳿� ���õ� �����μ�, ���û��׿� ���ϳ��� �񱳰� check�Ǿ� ���� ������ ���⼭ ������ �ȴ�.
  //
  if not OptionForm.C1.Checked then exit;       // ���û��� - ���ϳ��� ��

  // ProgressBar1�� 100 % ���� �����Ѵ�
  if (srcFileInfo.FileSize >= 1024*1024*1024) then KB:= 1024 else KB:= 1;

  // ���ϳ����� ���ϱ� ����, �ɼǿ� ���� �� ������ �ٸ��ٸ� ����� ��ü�� ���� �ʰ� ������������ �Ѵ�.
  if not (fileEqual in result) then exit;

  // ������� �ͼ� �Ѵ� 0����Ʈ��� ���� �����̴�.
  if (srcFileInfo.FileSize = 0) then begin      // �Ѵ� 0����Ʈ¥�� �����̶��
    result:= result + [fileEqual];              // ���ϰ� = �� ������ ����
    exit;                                       // ����������
  end;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ������ ���� ���� ������ �ǵ帮�� �����Ѵ�
  //
  try
    // Source ������ ����
    srcFile:= TFileStream.Create(src, fmOpenRead);
    srcFile.Seek(0, soFromBeginning);
  except                                        // src ������ �� �� ���ٸ�
    result:= result - [fileEqual];              // ���ϰ� = �� ������ �ٸ���
    result:= result + [srcOpenError];           // ���ϰ� = Source ������ �� �� ����
    exit;                                       // ����������
  end;

  try
    // Target ������ ����
    dstFile:= TFileStream.Create(dst, fmOpenRead);
    dstFile.Seek(0, soFromBeginning);
  except                                        // dst ������ �� �� ���ٸ�
    result:= result - [fileEqual];              // ���ϰ� = �� ������ �ٸ���
    result:= result + [dstOpenError];           // ���ϰ� = Target ������ �� �� ����
    srcFile.Free;                               // src ������ �ݴ´�
    exit;                                       // ����������
  end;

  if OptionForm.C11.Checked then begin          // ���û��� - �������� ����
    ProgressBar1.Position:= 0;                  // ProgressBar1�� ǥ�ø� ����� (0%)
    ProgressBar1.Max:= srcFileInfo.FileSize div KB; // ���������� ũ�⸦ ProgressBar�� 100%������ ����
    fileSizeLabel.Caption:= '['+inttoKB (srcFileInfo.FileSize)+']'; // ���������� ũ�� ǥ��
    fileRate.Caption:= inttostr(floor(ProgressBar1.Position/ProgressBar1.Max*100)) + '%';
  end;
  if OptionForm.C12.Checked then                // ���û��� - ��ü���� ����
    totalTemp64:= totalBytes64;                 // ProgressBar2�� ���� ��ġ�� ������ �д� (�߰��� ���������� ���� ũ�⸸ŭ ������Ű�� ����)

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ���� �߿��� �κ����μ�, ������ ������ ���ϴ� ���̴�
  //
  if OptionForm.C1.Checked then                 // ���û��� - ���ϳ��� ��
  repeat                                        // ������ ������ ���Ѵ�
    Application.ProcessMessages;                // ȭ���� �����ϰ� �̺�Ʈ�� �˻��� ƴ�� �ش�
    CheckPause;                                 // �Ͻ�����/���ߴ� ��ư�� �������� �˻��Ѵ�
    if stopCompare then break;                  // ����ڰ� ���ߴ� ��ư�� �������� ����������

    // maxRecord��ŭ �д´�. numRead�� ������ ���� ���̴�
    numRead1:= srcFile.Read(srcBuf, maxRecord);
    numRead2:= dstFile.Read(dstBuf, maxRecord);
    // ���� ����Ʈ�� ������ eof���� �� ���̹Ƿ� ����������
    if (numRead1 = 0) or (numRead2 = 0) then break;

    if OptionForm.C11.Checked then begin        // ���û��� - �������� ����
      // ������ �� % �о����� ProgressBar�� Label�� ǥ���Ѵ�
      ProgressBar1.Position:= ProgressBar1.Position + (numRead1 div KB);
      fileRate.Caption:= inttostr(floor(ProgressBar1.Position/ProgressBar1.Max*100)) + '%';
    end;
    if OptionForm.C12.Checked then begin        // ���û��� - ��ü���� ����
      ProgressBar2.Position:= ProgressBar2.Position + (numRead1 div folderKB);
      totalRate.Caption:= inttostr(floor(ProgressBar2.Position/ProgressBar2.Max*100)) + '%';
    end;

    // ���� ����Ʈ����ŭ �񱳸� �Ѵ�. ó�� ���� ������ i�� ������ ���� �Ѳ����� ���� �񱳸� �ϵ��� �Ѵ�
    if CompareMem (@srcBuf, @dstBuf, numRead1) = false then   // �������� �߰ߵǸ�
    begin
      for i:= 1 to numRead1 do                  // ���� ����Ʈ����ŭ �ٽ� �񱳸� �Ͽ� ��� �޶����� Ȯ���Ѵ�
      if (srcBuf[i] <> dstBuf[i]) then begin    // �������� �� ������ for���� ���������� �ȴ�
        if OptionForm.C12.Checked then begin    // ���û��� - ��ü���� ����
          // ������ ������� ���⼭ �׳� �������� ��� ���������� 100%�� ����ġ�� ������
          // �̷��� �Ʊ� ������ �ξ��� �����ٰ� ����ũ�⸸ŭ ������� �Ѵ�.
          ProgressBar2.Position:= (totalTemp64 + srcFileInfo.FileSize) div folderKB;
          totalRate.Caption:= inttostr(floor(ProgressBar2.Position/ProgressBar2.Max*100)) + '%';
        end;
        break;
      end;
      totalBytes64:= totalBytes64 + i-1;        // �� ���� Source ������ ����Ʈ�� ���հ踦 �����Ѵ�
      totalBytes.Caption:= '�� ����  Byte��: ' + inttostr3(totalBytes64);
      result:= result - [fileEqual];            // ���ϰ� = �� ������ �ٸ���
      result:= result + [dataDifferent];        // ���ϰ� = ���ϳ����� �ٸ���
      break;                                    // ����������
    end;                                        // ���� ����Ʈ����ŭ�� �񱳸� ���ߴ�

    totalBytes64:= totalBytes64 + numRead1;     // �� ���� Byte��
    totalBytes.Caption:= '�� ����  Byte��: ' + inttostr3(totalBytes64);
  until false;

  srcFile.Free;      // ������ �ݴ´�
  dstFile.Free;      // ������ �ݴ´�
end;


/////////////////////////////////////////////////////////////////////////////////////////////////
// ���� ���� ����� �м��Ͽ� ȭ�鿡 ������ ǥ���� �ش�
//
procedure TMainForm.DisplayResult (r: TcompareSet; src, dst: string);
var
  s: string;
begin
  // C:\Dir\FileName �� C:/Dir/FileName ó�� ��ģ��
  src:= Cure1 (src);
  dst:= Cure1 (dst);

  // �����½� ����θ� ����ϵ��� �Ѵ�.
  src:= toRelativePath (src, srcPath.Text);
  dst:= toRelativePath (dst, dstPath.Text);

  // �������� ó��
  if (fileEqual in r) then begin            // �� ������ ������
    SameFile.tag:= SameFile.tag + 1;        // �������� �Ǽ��� ++��Ų��
    SameFile.Caption:= '���� ���ϼ�: ' + inttostr3(SameFile.tag);
    if OptionForm.C8.Checked then           // ���û��� - �������� ǥ��
      if OptionForm.C9.Checked              // ���û��� - �ڼ��� ǥ��
      then Memo1.Lines.Add ('������ ����: ' + src + ' �� ' + dst)
      else Memo1.Lines.Add ('������ ����: ' + src);
    exit;                                   // ���̻� ���� �����Ƿ� ������
  end
  else Different:= Different + 1;           // ������ ���� ������ ����++

  // ���� �������� �߰ߵǾ��ٸ� �޸��忡 �� ������ ����Ѵ�.
  // �������� �� ���簣�� �� ���ϴ� �޸��� �� ���� �����ϴ� ���� ��Ģ���� �Ѵ�.
  s:= '';                                   // �޸��忡 ����� ���ڿ�

  // ������ ��¥/�ð��� ���� �ٸ��ٸ�
  if (dateDifferent in r) then s:= '���� �ð���';

  // ������ �Ӽ��� ���� �ٸ��ٸ�
  if (attrDifferent in r) then
  if (s='') then s:= '���� �Ӽ���'
  else s:= '�ð�,�Ӽ���';

  // ������ ũ�Ⱑ ���� �ٸ��ٸ�
  if (sizeDifferent in r) then
  if (s='') then s:= '���� ũ�Ⱑ'
  else begin
    if (s[5]<>',') then delete (s, 1, 5);   // �Ǿտ� '���� ' �ڸ� �����
    delete (s, length(s)-1, 2);             // �ְ����� '��'�� �����
    s:= s + ',ũ�Ⱑ';                      // ���� ',ũ�Ⱑ'�� �����ִ´�
  end;

  // ������ ��ҹ��� �̸��� ���� �ٸ��ٸ�
  if (nameDifferent in r) then
  if (s='') then s:= '���� �̸���'
  else begin
    if (s[5]<>',') then delete (s, 1, 5);   // �Ǿտ� '���� ' �ڸ� �����
    delete (s, length(s)-1, 2);             // �ְ����縦 �����
    s:= s + ',�̸���';                      // ���� ',�̸���'�� �����ִ´�
  end;

  // ���������̸��� ���� �ٸ��ٸ�
  if (dosnameDifferent in r) then
  if (s='') then s:= '�������� �̸���'
  else begin
    if (s[5]<>',') then delete (s, 1, 5);   // �Ǿտ� '���� ' �ڸ� �����
    delete (s, length(s)-1, 2);             // �ְ����縦 �����
    s:= s + ',���������̸���';              // ���� ',���������̸���'�� �����ִ´�
  end;

  // ������ ������ ���� �ٸ��ٸ�
  if (dataDifferent in r) then
  if (s='') then s:= '���� ������'
  else begin
    if (s[5]<>',') then delete (s, 1, 5);   // �Ǿտ� '���� ' �ڸ� �����
    delete (s, length(s)-1, 2);             // �ְ����縦 �����
    s:= s + ',������';                      // ���� ',������'�� �����ִ´�
  end;

  if (s > '') then
  if (not OptionForm.C9.Checked) then       // ���û��� - �ڼ��ϰ� ǥ�� �ƴϸ�
    Memo1.Lines.Add (s + ' �ٸ�: ' + src)
  else begin                                // ���û��� - �ڼ��ϰ� ǥ��
    Memo1.Lines.Add (s + ' �ٸ�: ' + src +' �� ' + dst);
    if (r <> [dataDifferent]) then begin    // ���븸 �ٸ� ��쿡�� ǥ������ �ʴ´�.
      s:= '   ����1: ';                     // Source ������ ������ �ڼ��� ǥ��
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

      s:= '   ����2: ';                     // Target ������ ������ �ڼ��� ǥ��
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

  // ���û��� - Source���� ǥ�� -> Source ������ ���� �� �����ߴٸ� (�� ���� ��찡 �ִ�)
  if (OptionForm.C6.Checked) then           // ���û��� - Source ���� ǥ��
  if (srcNotFound  in r) then Memo1.Lines.Add ('������ ����: ' + src) else // ���� �� ���α׷��� �߸� ¥�� �ʴ� �� �̷� ���� ���� ���� ���̴�
  if (srcOpenError in r) then Memo1.Lines.Add ('������ �� ���� ����: ' + src);

  // ���û��� - Target���� ǥ�� -> Target ������ ���� �� �����ߴٸ� (�� ���� ��찡 �ִ�)
  if (OptionForm.C7.Checked) then
  if (dstNotFound in r) or (dstOpenError in r) then begin
    notFound.tag:= notFound.tag + 1;
    notFound.Caption:= 'Target ���� ����: ' + inttostr3(notFound.tag);
    if (dstNotFound  in r) then Memo1.Lines.Add ('������ ����: ' + dst) else
    if (dstOpenError in r) then Memo1.Lines.Add ('������ �� ���� ����: ' + dst);
  end;

  // �׿� �˼����� ���� �߻���
  if (elseError in r) then Memo1.Lines.Add (src + ' ���� ���� �˼����� ����');
end;


/////////////////////////////////////////////////////////////////////////////////////////////////
// ����ڰ� ������ ���϶�� ����� ������ �� (��ư�� ������ ��) ����Ǵ� �Լ�
//
procedure TMainForm.runButtonClick(Sender: TObject);
var
  dt: string;
  src, dst: string;                         // ���� �̸��� �����ϴ� ��
  srcFullPath, dstFullPath: string;         // ����ڰ� �Է��� src�� dst�� Full Path�� �����ϴ� ��
  compareSet: TcompareSet;                  // CompareFile �Լ� ȣ�� ������� �޾ƿ��� ����
  folderSize: int64;                        // ���� source���丮�� ��ũ��
begin
  Memo1.Clear;                              // �޸����� �����

  if (srcPath.Text = '') then begin
    Memo1.Lines.Add ('Source ���丮�� �Է��ϼ���');
    srcPath.SetFocus; exit;                 // ����������
  end;

  if (dstPath.Text = '') then begin
    Memo1.Lines.Add ('Target ���丮�� �Է��ϼ���');
    dstPath.SetFocus; exit;                 // ����������
  end;

  // ����ڰ� ������ �Է��ϴ��� �� ���丮�� Full Path�� �˾Ƴ��� ó���Ѵ�
  srcFullPath:= ExpandFileName (srcPath.Text);
  dstFullPath:= ExpandFileName (dstPath.Text);

  // �̷��� Full Path�� ���ص� ��Ʈ ���丮�� ��쿡�� C:\ó�� �ǰ� �׿ܿ��� C:\Dir ó�� �ǹǷ� ���� ��� \�� �ٿ� ���Ͻ�Ų��
  if (srcFullPath[length(srcFullPath)] <> '\') then srcFullPath:= srcFullPath + '\';
  if (dstFullPath[length(dstFullPath)] <> '\') then dstFullPath:= dstFullPath + '\';

  // ���� �� ���丮�� ������ �񱳸� ���� �ʴ´�
  if (UpperCase(srcPath.Text) = UpperCase(dstPath.Text))
  or (UpperCase(srcFullPath ) = UpperCase(dstFullPath )) then begin
    Memo1.Lines.Add ('���� �� ���丮�� ��ġ�� �����ϴ�');
    Memo1.Lines.Add ('Source ���丮 = ' + Cure1(srcFullPath));
    Memo1.Lines.Add ('Target ���丮 = ' + Cure1(dstFullPath));
    srcPath.SetFocus; exit;                 // ����������
  end;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ���ٸ� ���������� ������ ���� �񱳸� �����Ѵ�
  //
  // ����ڰ� �Է��� ������ ���丮�� Combo Box�� List�� �߰��Ѵ�
  copyRecent (srcPath.Text, 1);
  copyRecent (dstPath.Text, 2);

  Caption:= '����...';                    // Title���� ���ڸ� �����ϰ�
  Application.Title:= Caption;              // Minimize���� ���� Title ���ڵ� �����Ѵ�

  Label1.Enabled:= false;                   // Source Path Label �Ұ�
  Label2.Enabled:= false;                   // Target Path Label �Ұ�
  srcPath.Enabled:= false;                  // Source Path ���� �Ұ�
  dstPath.Enabled:= false;                  // Source Path ���� �Ұ�
  runButton.Enabled:= false;                // ���ϱ� ��ư �Ұ�
  stopButton.Enabled:= true;                // ���ߴ� ��ư ����
  pauseButton.Enabled:= true;               // �Ͻ����� ��ư ����
  optButton.Enabled:= false;                // ���û��� ��ư �Ұ�
  closeButton.Enabled:= false;              // �� �� �� ��ư �Ұ�
  CheckBox1.Enabled:= false;                // ������丮 ������ Check �Ұ�

  Different:= 0;                            // ���δٸ� ���ϰ���
  totalFiles.tag:= 0;                       // ���ݱ��� ���� Source ������ �� ������ �����ϴ� ����
  totalFiles.Caption:= '�� Source ���ϼ�: ' + inttostr3(totalFiles.tag);
  totalBytes64:= 0;                         // ���ݱ��� ���� �� Byte���� �����ϴ� ����
  totalBytes.Caption:= '�� ����  Byte��: ' + inttostr3(totalBytes64);
  SameFile.tag := 0;                        // �������� ������ �����ϴ� ����
  SameFile.Caption := '���� ���ϼ�: ' + inttostr3(SameFile.tag);
  notFound.tag  := 0;                       // Source������ �ִµ� Target������ ���� ���� ������ �����ϴ� ����
  notFound.Caption  := 'Target ���� ����: ' + inttostr3(notFound.tag);

  stopCompare := false;
  pauseCompare:= false;
  folderKB:= 1;
  folderSizeLabel.Caption:= '';

  if OptionForm.C12.Checked then            // ���û��� - ��ü���� ����
  if OptionForm.C1.Checked then             // ���û��� - ���ϳ��� �� -> Source ���丮�� ���� ũ���� ������ ���Ѵ�
  begin
    Memo1.Lines.Add (Cure1(srcPath.Text) + ' ���丮...');
    folderSize:= getFolderSize(srcFullPath);
    // 1GB�� ������� KB������ ǥ���� �ش�. �ȱ׷��� range overflow ������.
    if (folderSize >= 1024*1024*1024) then folderKB:= 1024 else folderKB:= 1;
    ProgressBar2.Max:= folderSize div folderKB;
    // ��� ����� ���丮 ũ�⸦ ���� ǥ���� �޽����� �����ٰ� ���ٿ� �ش�
    // Memo1.Lines.Add ('�� ���丮 ũ��: ' + inttoKB(folderSize) + ' (' + inttostr3(folderSize) + ' ����Ʈ)'#13#10);
    Memo1.Lines.Strings[Memo1.Lines.Count-1]:= Cure1(srcPath.Text) + ' ���丮: ' + inttoKB(folderSize) + ' (' + inttostr3(folderSize) + ' ����Ʈ)';
    // ProgressBar �ڿ��� ǥ���� �ش�.
    folderSizeLabel.Caption:= '[' + inttoKB(folderSize) + ']';
  end;

  DatetimeToString (dt, 'hh:nn:ss', now);
  Memo1.Lines.Add ('['+dt+'] ���丮 �񱳸� �ϰ� �ִ� ���Դϴ�...');
  Xdir1.StartDir:= Cure2(srcFullPath);      // Ž�� ���� ���丮 �����ϰ�
  Xdir1.Recursive:= CheckBox1.Checked;      // Sub ���丮���� ���� ���� ������ �Ѵ�

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ���ݱ����� �񱳸� ���� �غ�����̾���, �������� ���۾��� �������� �Ѵ�
  //
  CheckPause;                               // �Ͻ����� ��ư�� �������� �˻��Ѵ�
  if not stopCompare then                   // ������ ��ư�� �������� �˻����� �ʴ´�
  while Xdir1.Find() do begin               // ������ �ϳ��� ã�´�
    Application.ProcessMessages;            // ����ڰ� ���� ������ �ߴ��� Event �˻縦 �� ƴ�� �ش�
    CheckPause;                             // �Ͻ����� ��ư�� �������� �˻��Ѵ�
    if stopCompare then break;              // ����ڰ� ���ߴ� ��ư�� �������� ����������
    if Xdir1.IsDirectory then continue;     // ������ �ƴϰ� ���丮��� ������ ��� Ž��

    src:= Xdir1.FileName;                   // Source ���� - S:\Dir1\FileName�� ����
    dst:= src;                              // Target ���� - �մ밡���� �ٲ�� �Ѵ�

    // dst = S:\Dir1\SubDir\FileName ���� ����ڰ� �Է��� Source Path�� Full Path�� S:\Dir1\ �� �����Ѵ�.
    // ���� ����� dst = FileName �Ǵ� SubDir\FileName�̴�
    Delete (dst, 1, length(srcFullPath));

    // �� ����� �տ��ٰ� ����ڰ� �Է��� Target Path�� Full Path�� T:\ �Ǵ� T:\Dir2\ �� ���δ�.
    dst:= dstFullPath + dst;

    // Target Directory�� �����ϴ��� �˻��Ͽ�, �������� �ʴ´ٸ� �ǳʶڴ�.
    // �̴� Xdir ������Ʈ�� ������� �ʰ� ��ü ����Ž�� ����� ���� ��� ������ ����.
    // ������ ������ ��
    // if (not DirectoryExists (ExtractFileDir(dst)));

    // -------------- �� �� �� �� ȣ �� -----------------------------
    // ������ ���Ѵ�. src, dst�� ������ Full Pathname�̴�.
    compareSet:= CompareFile (src, dst);

    // �񱳰���� ȭ�鿡 ǥ���� �ش�
    DisplayResult (compareSet, src, dst);
  end;

  // ���û��� - Source ������ ã�� �� ������ �Ϸ��ֱ�
  CheckPause;                               // �Ͻ����� ��ư�� �������� �˻��Ѵ�
  if not stopCompare then                   // ������ ��ư�� �������� �˻����� �ʴ´�
  if (OptionForm.C6.Checked) then begin
    Memo1.Lines.Add ('');
    Memo1.Lines.Add ('�� Source ���丮���� ���µ� Target ���丮���� �ִ� ����:');
    Xdir1.StartDir:= Cure2(dstFullPath);    // Ž�� ���� ���丮 �����ϰ�
    Memo1.tag:= 0;                          // Target ���丮���� �ִ� ������ ������ ����
    while Xdir1.Find do begin               // Target ���丮�� ������
      Application.ProcessMessages;          // ����ڰ� ���� ������ �ߴ��� Event �˻縦 �� ƴ�� �ش�
      CheckPause;                           // �Ͻ����� ��ư�� �������� �˻��Ѵ�
      if stopCompare then break;            // ����ڰ� ���ߴ� ��ư�� �������� ����������
      if Xdir1.IsDirectory then continue;   // ������ �ƴϰ� ���丮��� ������ ��� Ž��

      dst:= Xdir1.FileName;                 // Target ���� - T:\Dir1\FileName�� ����
      src:= dst;                            // Source ���� - �մ밡���� �ٲ�� �Ѵ�
      Delete (src, 1, length(dstFullPath)); // T:\Dir1\�� ����
      src:= srcFullPath + src;              // S:\Dir2\�� ���δ�

      if not File_Exists(src) then begin    // Source ������ ������
        if Memo1.tag=0 then Memo1.tag:= 1;  // Target ���丮���� �ִ� ������ �ϳ� �̻� �����
        Memo1.Lines.Add (toRelativePath(Cure1(dst),dstPath.Text));  // �� ������ ����Ѵ�
      end;
    end;    // while�� �� - Target ���丮�� �� ������
    // Target ���丮���� �ִ� ������ �־����� Tag�� ������� ������ �ش�
    if Memo1.tag = 1 then Memo1.tag:= 0
    // Target ���丮���� �ִ� ������ �ϳ��� ������ ���ٰ� ����� �ش�
    else Memo1.Lines.Strings[Memo1.Lines.Count-1]:= Memo1.Lines.Strings[Memo1.Lines.Count-1] + ' ����';
  end;                                      // OptionForm.C6.Checked ó�� ��

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // ��� ���۾��� �������Ƿ� ���� ������ ������� ���ش�
  //
  Application.ProcessMessages;          // ������ 100% ���¸� �ѹ� �׷��ټ� �ְ��Ѵ�
  if stopCompare then Xdir1.Stop        // Find ���߿� �ߴܵǸ� �ѹ� ȣ���� ��� �Ѵ�.
  else curFile.Caption:= '����:';       // ��������ÿ��� ����ǥ�ø� ����� (������ �������� ���д�)
  Caption:= '���丮 �񱳱�';          // Title���� ���ڸ� �����ϰ�
  Application.Title:= Caption;          // Minimize���� ���� Title ���ڵ� �����Ѵ�

  Label1.Enabled:= true;                // Source Path Label ����
  Label2.Enabled:= true;                // Target Path Label ����
  srcPath.Enabled:= true;               // Source Path ���� ����
  dstPath.Enabled:= true;               // Source Path ���� ����
  runButton.Enabled:= true;             // ���ϱ� ��ư ����
  stopButton.Enabled:= false;           // ���ߴ� ��ư �Ұ�
  // Ȥ�� Pause �����̸� Continue ���·� �ǵ�����
  if pauseCompare then pauseButtonClick (Sender);
  pauseButton.Enabled:= false;          // �Ͻ����� ��ư �Ұ�
  optButton.Enabled:= true;             // ���û��� ��ư ����
  closeButton.Enabled:= true;           // �� �� �� ��ư ����
  CheckBox1.Enabled:= true;             // ������丮 ������ Check ����

  if OptionForm.C11.Checked then begin  // ���û��� - �������� ����
    ProgressBar1.Position:= 0;          // ProgressBar1�� ǥ�ø� �����
    fileRate.Caption:= '0%';            // ���� ������ 0%�� �Ѵ�
    fileSizeLabel.Caption:= '';         // ����ũ�� ǥ�ø� �����.
  end;
  if OptionForm.C12.Checked then begin  // ���û��� - ��ü���� ����
    ProgressBar2.Position:= 0;          // ProgressBar1�� ǥ�ø� �����
    totalRate.Caption:= '0%';           // ��ü���� ������ 0%�� �Ѵ�
    folderSizeLabel.Caption:= '';       // ����ũ�� ǥ�ø� �����.
  end;

  // �޸��忡 �۾��� ���´ٴ� �޽����� �߰��Ѵ�
  if Memo1.Lines.Count > 0 then Memo1.Lines.Add ('');
  DatetimeToString (dt, 'hh:nn:ss', now);
  if (stopCompare = false)
  then Memo1.Lines.Add ('['+dt+'] ���丮 �񱳸� ���½��ϴ�.')
  else Memo1.Lines.Add ('['+dt+'] ���丮 �񱳸� �ߴ��߽��ϴ�.');

  // ���û��� - ��ü���� ���� ǥ�ø� ���� �ʵ��� �� ��������, ��� �񱳰� �� ���� �Ŀ� ��ü ���� ������ ����Ʈ���� ǥ���� �ش�
  if not OptionForm.C12.Checked then
    Memo1.Lines.Add ('�� ' + inttostr3(totalFiles.tag) + ' �� ����, ' + inttostr3(totalBytes64) + ' ����Ʈ�� ���߽��ϴ�');

  // ���������� ��� ������ ���Ͽ� �������� �߰ߵ��� �ʾҴٸ� ���� �޽����� �ϳ� �����ش�.
  if (stopCompare = false) then
  if (Different = 0) then Memo1.Lines.Add ('�� ���丮�� �������� �����ϴ�.');

  // Memo1.SetFocus;                    // Ŀ���� �޸������� �ű��
  srcPath.SetFocus;                     // Ŀ���� Source Path �Է�â���� �ű��
end;

end.

