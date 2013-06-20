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