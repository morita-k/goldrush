function fixmessage(url){
  jQuery.ajax({url: url, type: "PUT"});
  return false;
}

function insertAtCursor(objText, value) 
{
  objText.focus();
  if (document.selection) 
  {
    sel = document.selection.createRange();
    sel.text = value;
  }
  else if (objText.selectionStart || objText.selectionStart == '0') 
  {
    var curPos = objText.selectionStart;
    var firstPart = objText.value.substring(0, curPos);
    var secondPart = objText.value.substring(curPos, objText.value.length);
    objText.value = firstPart + value + secondPart;
    curPos += value.length;
    objText.setSelectionRange(curPos, curPos);
  }
  else 
  {
    objText.value += value;
  }    
}

function disableSubmit(form) {
  var elements = form.elements;
    for (var i = 0; i < elements.length; i++) {
      if (elements[i].type == 'submit') {
      elements[i].disabled = true;
    }
  }
}

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

function ufnum(x) {
  return x.replace(/,/g,"");
}

function disp(url, opt){
  if(opt === undefined) opt = "width=620,height=480,resizable=yes,scrollbars=yes";
  window.open(url, url.replace(/[^a-zA-Z]/g, ""), opt);
}

function disp_wide(url){
  disp(url, "width=820,height=480,resizable=yes,scrollbars=yes");
}

function popup_close() {
  var odoc = window.opener.document;
  odoc.getElementById("flashmsg").innerHTML = "<div style='font-size: 20px; color: green'>申請が登録されました。更新してください</div>"
  window.close();
  return false;
}

function set_expense_application(expense_application_id, expense_app_type_name, plan_buy_date, book_no, account_item, content, approximate_amount, tag_prefix) {
    window.opener.document.getElementById(tag_prefix + "_expense_app_type_name").innerHTML = expense_app_type_name
    window.opener.document.getElementById(tag_prefix + "_expense_application_id").setAttribute("value", expense_application_id);
    window.opener.document.getElementById(tag_prefix + "[buy_date]").setAttribute("value", plan_buy_date);
    window.opener.document.getElementById(tag_prefix + "[book_no]").setAttribute("value", book_no);
    window.opener.document.getElementById(tag_prefix + "[account_item]").setAttribute("value", account_item);
    window.opener.document.getElementById(tag_prefix + "[content]").setAttribute("value", content);
    window.opener.document.getElementById(tag_prefix + "[amount]").setAttribute("value", approximate_amount);
//    window.opener.document.getElementById('site_category_code_' + site_id).setAttribute("value", site_category_code);
    window.close();
}

function set_account_title(account_item, account_item_name, tag_prefix) {
    window.opener.document.getElementById(tag_prefix + "_account_item").value = account_item;
    if(window.opener.document.getElementById(tag_prefix + "_account_item_name")) window.opener.document.getElementById(tag_prefix + "_account_item_name").value = account_item_name;
//    window.opener.document.getElementById(tag_prefix + "_account_item").title = account_item_name;
    window.close();
}

function set_account_title2(account_item, tag_prefix) {
    window.opener.document.getElementById(tag_prefix + "[account_item]").value = account_item;
    window.close();
}

function set_payment_no(payment_no, payment_name, payment_name_kana) {
    window.opener.document.getElementById("expense_application_payment_no").value = payment_no;
    window.opener.document.getElementById("expense_application_payee_name").value = payment_name;
    window.opener.document.getElementById("expense_application_payee_name_kana").value = payment_name_kana;
    window.close();
}

function validateDate(objText)
{
  if (objText.value == null || objText == "") return true;
  
  var validformat = /^\d{4}\/\d{2}\/\d{2}$/;
  var returnval = false;
  if (!validformat.test(objText))
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

function convertToHankakuTime(strText)
{ 
  han = "0123456789:"; 
  zen = "０１２３４５６７８９："; 
  str = ""; 
  for (i=0; i<strText.length; i++) 
  { 
    c = strText.charAt(i); 
    n = zen.indexOf(c,0); 
    if (n >= 0) c = han.charAt(n); 
    str += c; 
  }
  return str; 
}

function validateTime(objText)
{
  if (objText.value == null || objText == "") return true;

  var validformat = /^\d{1,2}\:\d{1,2}$/;
  var returnval = false;
  
  if (objText.readOnly == true) return true;
  //半角に全角を変換です。
  objText.value = convertToHankakuTime(objText)
  if (!validformat.test(objText))
    alert("時間のフォーマットが正しくありません。「hh:mm」で入力してください。");
  else
  {
    var timefield = objText.split(":")[0];
    var minutefield = objText.split(":")[1];
    
    if ((parseInt(timefield) >= 0) && (parseInt(timefield) <= 48) && (parseInt(minutefield) >= 0) && (parseInt(minutefield) <= 59))
      returnval = true;
    else
      alert("時間のフォーマットが正しくありません。「hh:mm」で入力してください。");
  }
  if (returnval==false) objText.select();
  return returnval;
}

function copyAddress(from_prefix, to_prefix){
  $('#' + to_prefix + '_1').value = $F(from_prefix + '_1');
  $('#' + to_prefix + '_2').value = $F(from_prefix + '_2');
  $('#' + to_prefix + '_3').value = $F(from_prefix + '_3');
  $('#' + to_prefix + '_4').value = $F(from_prefix + '_4');
  return false;
}                                                       

function calcTax(amount, tax, other, plan){
  var _amount = Number(ufnum(amount.value));
  if(isNaN(_amount) || _amount == 0) return false;
  var _other = Number(ufnum(other.value));
  if(isNaN(_other)) return false;

  var _tax = 0;
  var _total = 0;
  if(_amount > 900 * 1000) { // 90万以上
    _total = Math.floor((5 * _amount - 500000) / 4);
    _tax = _total - _amount;
  }else{
    _total = Math.floor(_amount / 0.9);
    _tax = _total - _amount;
  }
  tax.value = fnum(_tax);
  plan.value = fnum(_total + _other);
  return true;
}

