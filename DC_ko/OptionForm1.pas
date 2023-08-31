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
//���û����� �о���δ�. TdcForm.ReadOptions �Լ����� �ϸ� ������ ���µ�,
//�ֳ��ϸ�, TdcForm.ReadOptions �Լ��� TdcForm.FormCreate �Լ��� ȣ���ϱ� �����̴�.
//TdcForm�� ���� �����ǰ� �״��� �� ToptForm�� �����ǹǷ�,
//���� ���������� ���� ToptForm.������ �� ������ �� Assign�Ϸ��� �ϸ�
//�翬�� ������ �� ���ۿ� ���� ���̴�.
//�׷��� �̷��� ToptForm.FormCreate �Լ����� ���ִ� ���̴�.
//
procedure TOptionForm.FormCreate(Sender: TObject);
var
    IniFile: TIniFile;
begin
    IniFile:= TIniFile.Create (MainForm.IniFileName);
     C1.Checked:= IniFile.ReadBool ('���û���', '���ϳ��� ��',                 C1.Checked);   //true
     C2.Checked:= IniFile.ReadBool ('���û���', '��¥�ð� ��',                 C2.Checked);   //true
     C3.Checked:= IniFile.ReadBool ('���û���', '���ϼӼ� ��',                 C3.Checked);   //false
     C4.Checked:= IniFile.ReadBool ('���û���', '�����̸� ��ҹ��� ��',        C4.Checked);   //true
     C5.Checked:= IniFile.ReadBool ('���û���', '���������̸� ��',             C5.Checked);   //false
     C6.Checked:= IniFile.ReadBool ('���û���', 'Source�� ã���� ������ ǥ��',   C6.Checked);   //true
     C7.Checked:= IniFile.ReadBool ('���û���', 'Target�� ã���� ������ ǥ��',   C7.Checked);   //true
     C8.Checked:= IniFile.ReadBool ('���û���', '������ ��� ���� ǥ���ϱ�',   C8.Checked);   //false
     C9.Checked:= IniFile.ReadBool ('���û���', '�ڼ��ϰ� ǥ���ϱ�',             C9.Checked);   //true
    C10.Checked:= IniFile.ReadBool ('���û���', '\ ��ſ� /�� ���� �ְ� �ϱ�',  C10.Checked);   //true
    C11.Checked:= IniFile.ReadBool ('���û���', '�������� ���� ǥ��',         C11.Checked);   //true
    C12.Checked:= IniFile.ReadBool ('���û���', '��ü���� ���� ǥ��',         C12.Checked);   //true
    C13.Checked:= IniFile.ReadBool ('���û���', '������ ���û��� ����',         C13.Checked);   //true
    C14.Checked:= IniFile.ReadBool ('���û���', '����ũ�� ���Ϻ�',            C14.Checked);   //true
    IniFile.Free;
end;

//���¸� ������ �д� (��ҽ� ���� �����ص� ������ �ǵ����� ����)
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

//��ҽ� �Ʊ� �����ص� ������ �����Ѵ�
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

