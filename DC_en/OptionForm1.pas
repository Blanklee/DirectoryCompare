unit OptionForm1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, IniFiles;

type
  TOptionForm = class(TForm)
    C1: TCheckBox;
    C2: TCheckBox;
    C3: TCheckBox;
    C4: TCheckBox;
    C5: TCheckBox;
    C6: TCheckBox;
    C7: TCheckBox;
    C8: TCheckBox;
    C9: TCheckBox;
    C10: TCheckBox;
    C11: TCheckBox;
    C12: TCheckBox;
    C13: TCheckBox;
    C14: TCheckBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OptionForm: TOptionForm;


implementation

uses MainForm1;

{$R *.DFM}

/////////////////////////////////////////////////////////////////////////////////////////////////
//선택사항을 읽어들인다. TdcForm.ReadOptions 함수에서 하면 에러가 나는데,
//왜냐하면, TdcForm.ReadOptions 함수는 TdcForm.FormCreate 함수가 호출하기 때문이다.
//TdcForm이 먼저 생성되고 그다음 이 ToptForm이 생성되므로,
//아직 생성되지도 않은 ToptForm.뭐뭐뭐 의 내용을 막 Assign하려고 하면
//당연히 에러가 날 수밖에 없는 것이다.
//그래서 이렇게 ToptForm.FormCreate 함수에서 해주는 것이다.
//
procedure TOptionForm.FormCreate(Sender: TObject);
var
    IniFile: TIniFile;
begin
    IniFile:= TIniFile.Create (MainForm.IniFileName);
     C1.Checked:= IniFile.ReadBool ('선택사항', '파일내용 비교',                 C1.Checked);   //true
     C2.Checked:= IniFile.ReadBool ('선택사항', '날짜시각 비교',                 C2.Checked);   //true
     C3.Checked:= IniFile.ReadBool ('선택사항', '파일속성 비교',                 C3.Checked);   //false
     C4.Checked:= IniFile.ReadBool ('선택사항', '파일이름 대소문자 비교',        C4.Checked);   //true
     C5.Checked:= IniFile.ReadBool ('선택사항', '도스파일이름 비교',             C5.Checked);   //false
     C6.Checked:= IniFile.ReadBool ('선택사항', 'Source를 찾을수 없을때 표시',   C6.Checked);   //true
     C7.Checked:= IniFile.ReadBool ('선택사항', 'Target을 찾을수 없을때 표시',   C7.Checked);   //true
     C8.Checked:= IniFile.ReadBool ('선택사항', '비교중인 모든 파일 표시하기',   C8.Checked);   //false
     C9.Checked:= IniFile.ReadBool ('선택사항', '자세하게 표시하기',             C9.Checked);   //true
    C10.Checked:= IniFile.ReadBool ('선택사항', '\ 대신에 /도 쓸수 있게 하기',  C10.Checked);   //true
    C11.Checked:= IniFile.ReadBool ('선택사항', '현재파일 비교율 표시',         C11.Checked);   //true
    C12.Checked:= IniFile.ReadBool ('선택사항', '전체파일 비교율 표시',         C12.Checked);   //true
    C13.Checked:= IniFile.ReadBool ('선택사항', '끝날때 선택사항 저장',         C13.Checked);   //true
    C14.Checked:= IniFile.ReadBool ('선택사항', '같은크기 파일비교',            C14.Checked);   //true
    IniFile.Free;
end;

//상태를 저장해 둔다 (취소시 지금 저장해둔 값으로 되돌리기 위함)
procedure TOptionForm.FormActivate(Sender: TObject);
begin
     C1.tag:= integer( C1.Checked);
     C2.tag:= integer( C2.Checked);
     C3.tag:= integer( C3.Checked);
     C4.tag:= integer( C4.Checked);
     C5.tag:= integer( C5.Checked);
     C6.tag:= integer( C6.Checked);
     C7.tag:= integer( C7.Checked);
     C8.tag:= integer( C8.Checked);
     C9.tag:= integer( C9.Checked);
    C10.tag:= integer(C10.Checked);
    C11.tag:= integer(C11.Checked);
    C12.tag:= integer(C12.Checked);
    C13.tag:= integer(C13.Checked);
    C14.tag:= integer(C14.Checked);
end;

//취소시 아까 저장해둔 것으로 복귀한다
procedure TOptionForm.BitBtn2Click(Sender: TObject);
begin
     C1.Checked:= boolean( C1.tag);
     C2.Checked:= boolean( C2.tag);
     C3.Checked:= boolean( C3.tag);
     C4.Checked:= boolean( C4.tag);
     C5.Checked:= boolean( C5.tag);
     C6.Checked:= boolean( C6.tag);
     C7.Checked:= boolean( C7.tag);
     C8.Checked:= boolean( C8.tag);
     C9.Checked:= boolean( C9.tag);
    C10.Checked:= boolean(C10.tag);
    C11.Checked:= boolean(C11.tag);
    C12.Checked:= boolean(C12.tag);
    C13.Checked:= boolean(C13.tag);
    C14.Checked:= boolean(C14.tag);
end;

end.

