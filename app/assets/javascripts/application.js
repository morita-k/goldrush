// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require_tree .

$(function() {
	$('a[rel*=leanModal]').click(function(event){
		if($('[name=\"ids[]\"]:checked').length <= 0){
			alert('取引先担当者を選択してください。');
			event.stopImmediatePropagation();
			return false;
		}
	}).leanModal({ top : 150, overlay : 0.4, closeButton: ".modal_close"});
});

function groupSelectedCheck(){
	return $('#groupTable input[type=\"checkbox\"]:checked').size() != 0;
};

function checkTest(){
	var ids = $('[name=\"ids[]\"]:checked');
	if(ids.length <= 0){
		alert('取引先担当者を選択してください。');
		return false;
	}
	var errors = [];
	var sales = [];
	$.each(ids, function(i, obj) {
		var sales_pic = $(obj).closest("tr").find("a.sales_pic")[0].name;
		if(sales_pic.length == 0){
			errors.push(">" + $(obj).closest("tr").find("a.bp_name").html() + " " + $(obj).closest("tr").find("a.bp_pic_name").html());
		};
		sales.push(sales_pic);
	});
	if(errors.length > 0){
		alert("担当営業が設定されていません。\n" + errors.join("\n"));
		return false;
	}
	if($.unique(sales).length > 1){
		alert("複数の取引先担当者にメールを送信する場合は、担当営業が同一である必要があります。\n担当営業を変更するか、担当営業毎に分けてメールを送信してください。")
			return false;
	}
	return true;
};

$(document).ready(function(){
		$('#collapseForm').on('hide.bs.collapse', function(){
				$('#collapseArrow').animate({rotate: 90})
		});
		$('#collapseForm').on('show.bs.collapse', function(){
				$('#collapseArrow').animate({rotate: 0})
		});
});
