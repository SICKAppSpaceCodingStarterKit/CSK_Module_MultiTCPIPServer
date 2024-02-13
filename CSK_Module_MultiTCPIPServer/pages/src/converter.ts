export function convertToList(value) {
  return JSON.parse(value)
}

export function bool2str(newbool){
  var myString: string = String(newbool);
  return myString
}

export function num2str(newnum){
  return String(newnum)
}

export function str2num(newstr){
  return Number(newstr)
}
