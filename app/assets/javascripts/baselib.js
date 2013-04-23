/*
 * ダブルクリック対策
 */
function disableSubmit(form) {
  var elements = form.elements;
    for (var i = 0; i < elements.length; i++) {
      if (elements[i].type == 'submit') {
      elements[i].disabled = true;
    }
  }
}

/*
 * カレンダーの表示位置を調整
 */
function offsetCalendar(target_tag, input_tag) {
//    target_tag.style.position = "absolute";
    var obj = absolutePosition(input_tag);

    var inW = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth
    if(obj.left > inW - 150){
      target_tag.style.left = inW - 150;
    }else{
      target_tag.style.left = obj.left;
    }
    target_tag.style.top = obj.top + input_tag.offsetHeight;
}

/*
 * 要素の絶対位置を取得
 */
function absolutePosition(target){
  var obj = new Object();
  obj.top = target.offsetTop;
  obj.left = target.offsetLeft;
  var parent = target.offsetParent;
  while(parent){
    obj.top = obj.top + parent.offsetTop;
    obj.left = obj.left + parent.offsetLeft;
    parent = parent.offsetParent;
  }
  return obj;
}

/*
 * 数字のカンマ区切り関数
 */
function fnum(x) {
    var s = "" + x;
    var p = s.indexOf(".");
    if (p < 0) {
        p = s.length;
    }
    var r = s.substring(p, s.length);
    for (var i = 0; i < p; i++) {
        var c = s.substring(p - 1 - i, p - 1 - i + 1);
        if (c < "0" || c > "9") {
            r = s.substring(0, p - i) + r;
            break;
        }
        if (i > 0 && i % 3 == 0) {
            r = "," + r;
        }
        r = c + r;
    }
    return r;
}

/*
 * 数字のカンマ区切り戻し関数
 */
function ufnum(x) {
  return x.replace(/,/g,"");
}

/*
 * ポップアップ表示
 */
function disp(url){
  window.open(url, url.replace(/[^a-zA-Z]/g, ""), "width=620,height=480,resizable=yes,scrollbars=yes");
}

/*
 * ポップアップ表示(ちょっと幅広)
 */
function disp_wide(url){
  window.open(url, url.replace(/[^a-zA-Z]/g, ""), "width=820,height=480,resizable=yes,scrollbars=yes");
}

/*
 * 日付フォーマットチェック
 */
function validateDate(objText)
{
  if (objText == null || objText.value == "") return true;
  
  var validformat = /^\d{4}\/\d{2}\/\d{2}$/;
  var returnval = false;
  if (!validformat.test(objText.value))
    alert("日付のフォーマットが正しくありません。「yyyy/mm/dd」で入力してください。");
  else
  {
    var yearfield = objText.value.split("/")[0];
    var monthfield = objText.value.split("/")[1];
    var dayfield = objText.value.split("/")[2];
    var dayobj = new Date(yearfield, monthfield-1, dayfield);

    if ((dayobj.getMonth()+1!=monthfield)||(dayobj.getDate()!=dayfield)||(dayobj.getFullYear()!=yearfield))
      alert("日付のフォーマットが正しくありません。「yyyy/mm/dd」で入力してください。");
    else
      returnval = true;
  }
  if (returnval==false) objText.select();
  return returnval;
}

/*
 * 時間フォーマットチェック
 */
function validateTime(objText)
{
  if (objText.value == "") return true;

  var validformat = /^\d{1,2}\:\d{1,2}$/;
  var returnval = false;
  
  if (objText.readOnly == true) return true;
  
  if (!validformat.test(objText.value))
    alert("時間のフォーマットが正しくありません。「hh:mm」で入力してください。");
  else
  {
    var timefield = objText.value.split(":")[0];
    var minutefield = objText.value.split(":")[1];
    
    if ((parseInt(timefield) >= 0) && (parseInt(timefield) <= 48) && (parseInt(minutefield) >= 0) && (parseInt(minutefield) <= 59))
      returnval = true;
    else
      alert("時間のフォーマットが正しくありません。「hh:mm」で入力してください。");
  }
  if (returnval==false) objText.select();
  return returnval;
}


function getModelName(url)
{
  return location.href.split(location.host)[1].split("/")[1];
}