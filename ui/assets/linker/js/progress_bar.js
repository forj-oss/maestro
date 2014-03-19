function progress(control, percentage){
	//canvas initialization
	var canvas = document.getElementById(control);
	var ctx = canvas.getContext("2d");
	//dimensions
	var W = canvas.width;
	var H = canvas.height;
	//Variables
	var degrees = 0;
	var new_degrees = 0;
	var difference = 0;
	var color = "#0096d6"; //green looks better to me
	var bgcolor = "#CCC";
	var text;
	var animation_loop, redraw_loop;
	
	function init()
	{
		//Clear the canvas everytime a chart is drawn
		ctx.clearRect(0, 0, W, H);
		
		//Background 360 degree arc
		ctx.beginPath();
		ctx.strokeStyle = bgcolor;
		ctx.lineWidth = 11;
		ctx.arc(W/2, H/2, 50, 0, Math.PI*2, false); //you can see the arc now
		ctx.stroke();
		
		//gauge will be a simple arc
		//Angle in radians = angle in degrees * PI / 180
		var radians = degrees * Math.PI / 180;
		ctx.beginPath();
		if(percentage<50){
      ctx.strokeStyle = '#0096d6';
      ctx.fillStyle = '#0096d6';
		}
		if(percentage>50){
      ctx.strokeStyle = '#EE7836';
      ctx.fillStyle = '#EE7836';
		}
		if(percentage>75){
      ctx.strokeStyle = '#DA3610';
      ctx.fillStyle = '#DA3610';
		}
		//ctx.strokeStyle = color;
		ctx.lineWidth = 11;
		//The arc starts from the rightmost end. If we deduct 90 degrees from the angles
		//the arc will start from the topmost end
		ctx.arc(W/2, H/2, 50, 0 - 90*Math.PI/180, radians - 90*Math.PI/180, false);
		//you can see the arc now
		ctx.stroke();
		
		//Lets add the text
		//ctx.fillStyle = color;
		ctx.font = "30px sans-serif";
		text = Math.round(degrees/360*100) + "%";
		//Lets center the text
		//deducting half of text width from position x
		text_width = ctx.measureText(text).width;
		//adding manual value to position y since the height of the text cannot
		//be measured easily. There are hacks but we will keep it manual for now.
		ctx.fillText(text, W/2 - text_width/2, H/2 + 10);
	}
	
	function draw()
	{
		//Cancel any movement animation if a new chart is requested
    if(typeof animation_loop !== undefined) clearInterval(animation_loop);
		
		new_degrees = percentage*3.6;
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
		if(degrees == new_degrees)
			clearInterval(animation_loop);
		
		if(degrees < new_degrees)
			degrees++;
		else
			degrees--;
		init();
	}
	
	draw();
}