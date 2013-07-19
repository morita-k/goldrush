// ポップオーバー属性の追加(見出しあり)
$(function() {
    $('[rel=popover]').popover();
});

// ポップオーバー属性の追加(見出しなし)
$(function() {
    $('[rel=popover-without-title]').popover({
      template: '<div class="popover"><div class="arrow"></div><div class="popover-inner"><div class="popover-content"><p></p></div></div></div>'
    });
});

// 引数に指定した文字列の長さを計算する
function getTextWidth(text, style){
  key = "calc_text_length_" + Date.now();
  $("body").append("<span id='" + key + "' style='display:none !important;" + style + "'>" + text + "</span>");
  var width = $("#" + key).width();
  $("#" + key).remove();
  return width;
}


var BuisinessPartnerForm = (function(){
  klass = function(form_id_list){
    this.id_list = form_id_list;
  }
  
  klass.prototype.setId = function( id ){
    $( "#" + this.id_list.business_partner_id ).val( id );
  }
  
  klass.prototype.getId = function(){
    return $( "#" + this.id_list.business_partner_id ).val();
  }
  
  klass.prototype.setName = function( name ){
    $( "#" + this.id_list.business_partner_name ).val( name );
  }
  
  klass.prototype.getName = function(){
    return $( "#" + this.id_list.business_partner_name ).val();
  }
  
  return klass;
})();

var BpPicForm = (function(){
  klass = function(form_id_list){
    this.id_list = form_id_list;
  }
  
  klass.prototype.setId = function( id ){
    $( "#" + this.id_list.bp_pic_id ).val( id );
  }
  
  klass.prototype.getId = function( id ){
    return $( "#" + this.id_list.bp_pic_id ).val();
  }
  
  klass.prototype.setName = function( name ){
    $( "#" + this.id_list.bp_pic_name ).val( name );
  }
  
  klass.prototype.getName = function(){
    return $( "#" + this.id_list.bp_pic_name ).val();
  }
  
  return klass;
})();


function openBpPicList(url) {
  alert("openBpPicList was deprecated!");
  var bp_id = document.busines_pertner.getId();
  if ( bp_id != ""){ disp_wide(url + '&id=' + bp_id ); }
}

document.setBp = function(bp) {
  alert("setBp was deprecated!");
  document.busines_pertner.setId( bp.id );
  document.busines_pertner.setName( bp.business_partner_name );
  document.bp_pic.setId( "" );
  document.bp_pic.setName( "" );
}

function clearBp(){
  alert("clearBp was deprecated!");
  document.busines_pertner.setId( "" );
  document.busines_pertner.setName( "" );
  document.bp_pic.setId( "" );
  document.bp_pic.setName( "" );
}

document.setBpPic = function(bp_pic){
  alert("setBpPic was deprecated!");
  document.bp_pic.setId( bp_pic.id );
  document.bp_pic.setName( bp_pic.bp_pic_name );
}

function clearBpPic(){
  alert("clearBpPic was deprecated!");
  document.bp_pic.setId( "" );
  document.bp_pic.setName( "" );
}

document.setContactUser = function(user){
    $("#biz_offer_contact_pic_id").val( user.pic_id );
    $("#contact_pic_name").val( user.pic_name );
}

function clearContactUser(){
    $("#biz_offer_contact_pic_id").val( "" );
    $("#contact_pic_name").val( "" );
}

document.setSalesUser = function(user){
    $("#biz_offer_sales_pic_id").val( user.pic_id );
    $("#sales_pic_name").val( user.pic_name );
}

function clearSalesUser(){
    $("#biz_offer_sales_pic_id").val( "" );
    $("#sales_pic_name").val( "" );
}
