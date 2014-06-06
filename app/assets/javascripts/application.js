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
	return true;
};

$(function () {
	$("input[type='radio'].starred_radio").on("change", function() {
		var target_id = this.getAttribute("target_id");
		var model = this.getAttribute("model");
		var post_url = this.getAttribute("post_url");
		if(!target_id){
			//
		}else{
			$.post(post_url, {model: model, target_id: target_id, starred: this.value}, function(tag_tag){ return function(data, status, xhr){
				//
			}}(this));
		}
	});
});

$(function() {
	$(".linked_star a").click(function () {
		$.ajax({
			type: "PUT",
			url: this.getAttribute("href"),
			success: function(data) {
				eval(data);
			}
		});
		return false;
	});
});
