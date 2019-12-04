/*
Name: Main Js file for Crypterio Template
Date: 20 January 2019
Themeforest TopHive : https://themeforest.net/user/tophive
*/


'use strict';
jQuery(document).ready(function() {
	jQuery(document).on('click', '.crypt-header i.menu-toggle', function(){
		jQuery('.crypt-mobile-menu').toggleClass('show');
		jQuery(this).toggleClass('open')
	});

	jQuery(document).on('hover', '.crypt-mega-dropdown-toggle', function(){
		jQuery('.crypt-mega-dropdown-menu-block').toggleClass('shown');
	});
	jQuery(document).on('click', '.crypt-mega-dropdown-toggle', function(e){
		e.preventDefault();
		jQuery('.crypt-mega-dropdown-menu-block').toggleClass('shown');
	});
	jQuery('[data-toggle="tooltip"]').tooltip();

	jQuery('#crypt-tab a').on('click', function (e) {
	  	
	  	e.preventDefault();

	  	var x = jQuery(this).attr('href');
		jQuery(this).parents().find('.crypt-tab-content .tab-pane').removeClass('active');
		jQuery(this).parents().find('.crypt-tab-content .tab-pane' + x).addClass('active');
	});

	jQuery(document).on( 'click', '.crypt-coin-select a', function(e){
		e.preventDefault();
		var div = jQuery(this).attr('href');
		jQuery('.crypt-dash-withdraw').removeClass('d-block').addClass('d-none');
		jQuery(div).removeClass('d-none').addClass('d-block');
	});
	var path = window.location.href; // because the 'href' property of the DOM element is the absolute path

 	jQuery('ul.crypt-heading-menu > li > a').each(function() {
  		if (this.href === path) {
   			jQuery(this).parent('li').addClass('active');
  		}else{
   			jQuery(this).parent('li').removeClass('active');
  		}
  		jQuery('.crypt-box-menu').removeClass('active');
 	});
	if(document.getElementById('crypt-candle-chart')){
	 	new TradingView.widget(
		 	{
		  		"autosize": true,
			  	"symbol": "NASDAQ:AAPL",
			  	"interval": "D",
			  	"timezone": "Etc/UTC",
			  	"theme": "Light",
			  	"style": "1",
			  	"locale": "en",
			  	"toolbar_bg": "rgba(255, 255, 255, 1)",
			  	"enable_publishing": false,
			  	"allow_symbol_change": true,
			  	"container_id": "crypt-candle-chart"
			}
	  	);
	}
});