/*

*/

function progress(control, percentage, task){
	//canvas initialization
	var canvas = document.getElementById(control);
	var current = document.getElementById(control).getAttribute("data-current");
	var bg_color = document.getElementById(control).getAttribute("data-bg-color");
	var font_color = document.getElementById(control).getAttribute("data-font-color");
	var new_degrees = 0;
	var degrees = 0;
	if(task === 'move_to'){
    if(current !== undefined){
      degrees = current*3.6;
      degrees = Math.round(degrees);
      new_degrees = percentage*3.6;
      new_degrees = Math.round(new_degrees);
      document.getElementById(control).setAttribute("data-current", ""+percentage+"");
    }
	}
	var ctx = canvas.getContext("2d");
	//dimensions
	var W = canvas.width;
	var H = canvas.height;
	//Variables
	var difference = 0;
	var bgcolor = "#E6E7E7";
	if(bg_color){
    bgcolor = bg_color;
	}
	
	var text;
	var animation_loop, redraw_loop;
	
	function init()
	{
		//Clear the canvas everytime a chart is drawn
		ctx.clearRect(0, 0, W, H);
		
		//Background 360 degree arc
		ctx.beginPath();
		ctx.strokeStyle = bgcolor;
		ctx.lineWidth = 8;
		ctx.arc(W/2, H/2, (H-ctx.lineWidth)/2, 0, Math.PI*2, false); //you can see the arc now
		ctx.stroke();
		
		//gauge will be a simple arc
		//Angle in radians = angle in degrees * PI / 180
		var radians = degrees * Math.PI / 180;
		ctx.beginPath();
		if(percentage<=50){
      ctx.strokeStyle = '#47CC3A';
      ctx.fillStyle = '#666666';
      if(font_color){
        ctx.fillStyle = font_color;
      }
      
		}
		if(percentage>50){
      ctx.strokeStyle = '#F09101';
      ctx.fillStyle = '#666666';
      if(font_color){
        ctx.fillStyle = font_color;
      }
		}
		if(percentage>=75){
      ctx.strokeStyle = '#D6332C';
      ctx.fillStyle = '#666666';
      if(font_color){
        ctx.fillStyle = font_color;
      }
		}
		//ctx.strokeStyle = color;
		ctx.lineWidth = 8;
		//The arc starts from the rightmost end. If we deduct 90 degrees from the angles
		//the arc will start from the topmost end
		ctx.arc(W/2, H/2, (H-ctx.lineWidth)/2, 0 - 90*Math.PI/180, radians - 90*Math.PI/180, false);
		//you can see the arc now
		ctx.stroke();
		
		//Lets add the text
		//ctx.fillStyle = color;
		ctx.font = "24px Open Sans Semibold, sans-serif";
		text = Math.round(degrees/360*100) + "%";
		//Lets center the text
		//deducting half of text width from position x
		text_width = ctx.measureText(text).width;
		TH = parseInt(ctx.font);
		ALW = ctx.lineWidth
		//Fill the text to the center with the formula Canvas Height (H), Text Height (TH) and Arc LineWidth (ALW)
		ctx.fillText(text, W/2 - text_width/2, ((H+TH)-ALW)/2);
	}
	
	function draw()
	{
		//Cancel any movement animation if a new chart is requested
    if(typeof animation_loop !== undefined) clearInterval(animation_loop);
		
		new_degrees = percentage*3.6;
		new_degrees = Math.round(new_degrees);
		difference = new_degrees - degrees;
		//This will animate the gauge to new positions
		//The animation will take 1 second
		//time for each frame is 1sec / difference in degrees
		animation_loop = setInterval(animate_to, 1000/difference);
	}
	
	//function to make the chart move to new degrees
	function animate_to()
	{
		//clear animation loop if degrees reaches to new_degrees
		//console.log('deg:'+degrees+', new_degrees:'+new_degrees);
		if(degrees == new_degrees)
			clearInterval(animation_loop);
		
		if(degrees < new_degrees){
			degrees++;
		}else{
			degrees--;
		}
		init();
	}
	
	draw();
}