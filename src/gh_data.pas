{
    Greyhound
    Copyright (C) 2012  -  Marcos Douglas B. dos Santos

    See the files COPYING.GH, included in this
    distribution, for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}

unit gh_Data;

{$i gh_def.inc}

interface

uses
  // fpc
  Classes, SysUtils, DB, fpjson,
  // gh
  gh_Global;

type
  EghDataError = class(EghError);
  TghDataObject = class(TghObject);

{ Interfaces }

  IghDataSet = interface(IghInterface)
    function GetEOF: Boolean;
    function GetFields: TFields;
    function GetState: TDataSetState;
    // dataset
    function GetActive: Boolean;
    function GetRecordCount: Longint;
    procedure Close;
    procedure Open;
    procedure Insert;
    procedure Append;
    procedure Edit;
    procedure Delete;
    procedure Cancel;
    procedure Post;
    procedure First;
    procedure Prior;
    procedure Next;
    procedure Last;
    function IsEmpty: Boolean;
    function FieldByName(const AFieldName: string): TField;
    property Active: Boolean read GetActive;
    property EOF: Boolean read GetEOF;
    property Fields: TFields read GetFields;
    property RecordCount: Longint read GetRecordCount;
    property State: TDataSetState read GetState;
  end;

{ Classes }

  TghDataColumn = TField;
  TghDataColumns = TFields;

  TghDataParams = class(TParams)
  strict private
    FLocked: Boolean;
  public
    procedure Lock;
    procedure UnLock;
    // Create a param automatically if not exist.
    function ParamByName(const AName: string): TParam; reintroduce;
    // An alias less verbose; changed the default property.
    property Param[const AName: string]: TParam read ParamByName; default;
  end;

  TghDataRow = class(TghDataParams)
  end;

  TghDataAdapter = class(TghDataObject)
  private
    FDataRow: TghDataRow;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Adapt(ASource: TObject); virtual; abstract;
    property DataRow: TghDataRow read FDataRow;
  end;

  TghJSONDataAdapter = class(TghDataAdapter)
  public
    procedure Adapt(ASource: TObject); override;
  end;

implementation

{ TghDataParams }

procedure TghDataParams.Lock;
begin
  FLocked := True;
end;

procedure TghDataParams.UnLock;
begin
  FLocked := False;
end;

function TghDataParams.ParamByName(const AName: string): TParam;
var
  lParam: TParam;
begin
  lParam := FindParam(AName);
  if not Assigned(lParam) then
  begin
    if FLocked then
      raise EghDataError.Create(Self, 'Params were locked.');
    lParam := TParam.Create(Self);
    lParam.Name := AName;
  end;
  Result := lParam as TParam;
end;

{ TghDataAdapter }

constructor TghDataAdapter.Create;
begin
  inherited;
  FDataRow := TghDataRow.Create;
end;

destructor TghDataAdapter.Destroy;
begin
  FDataRow.Free;
  inherited Destroy;
end;

{ TghJSONDataAdapter }

procedure TghJSONDataAdapter.Adapt(ASource: TObject);
var
  i: Integer;
  lJson: TJSONObject absolute ASource;
  lName: string;
  lData: TJSONData;
  lParam: TParam;
begin
  DataRow.Clear;
  for i := 0 to lJson.Count-1 do
  begin
    lName := lJson.Names[i];
    lData := lJson.Items[i];
    lParam := DataRow[lName];
    case lData.JSONType of
      jtNumber:
        begin
          if lData is TJSONFloatNumber then
            lParam.AsFloat := lData.AsFloat
          else
          if lData is TJSONIntegerNumber then
            lParam.AsInteger := lData.AsInteger
        end;
      jtString:
        lParam.AsString := lData.AsString;
      jtBoolean:
        lParam.AsBoolean := lData.AsBoolean;
      jtNull:
        lParam.Value := Null;
    else
      raise EghDataError.Create(Self, 'JSONType not supported.');
    end;
  end;
end;

end.
