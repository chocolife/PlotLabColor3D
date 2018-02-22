package
{	
	import flash.net.*;
	import flash.events.*;
	import flash.text.*;
	import flash.ui.Mouse;
	import flash.system.Security;
	import org.papervision3d.view.*
	import org.papervision3d.objects.*;
	import org.papervision3d.materials.*
	import org.papervision3d.objects.primitives.*
	import org.papervision3d.core.geom.*;
	import org.papervision3d.core.geom.renderables.*;
	import org.papervision3d.materials.special.ParticleMaterial;
	import org.papervision3d.objects.special.ParticleField;
	import org.papervision3d.materials.utils.MaterialsList;
	import net.hires.debug.Stats;
	
	
	[SWF(width = "500", height = "400", frameRate = "30", backgroundColor = "0x000000")]
	
	public class PlotLab extends BasicView
	{

		private var world:BasicView = new BasicView();
		private var file:FileReference = new FileReference();
		private var pChips:Particles = new Particles("pChips");
		private var isMouseDown:Boolean = false;
		private var oldX:Number = 0;
		private var oldY:Number = 0;
		private var nowX:Number = 0;
		private var nowY:Number = 0;
		private var targetRot:Number = 180;
		private var targetPitch:Number = 0;	
		private var rot:Number = 0;
		private var pitch:Number = 0;
		private var text1:TextField = new TextField();
		private var lab_colors:Array = [];
		private var mes1:String = 'Load L*a*b* coordinates';
		private var mes2:String = '...Loading';
		
		public function PlotLab():void {
			
			// via http://5ivestar.org/blog/2008/12/wonderfl-webproxy/ 
			// Thanks!!
			//Security.loadPolicyFile("http://5ivestar.org/proxy/crossdomain.xml");
			//Security.loadPolicyFile("http://dl.dropbox.com/u/271700/crossdomain.xml");
			addChild(new Stats({bg: 0x000000, fps: 0xC0C0C0, ms: 0x505050, mem: 0x707070, memmax: 0xA0A0A0}));
			world.startRendering();
			addChild(world);
		
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, completeHandler);
			
			//by default, loading the coordinates of a fullcolor image on AdobeRGB   
			//loader.load(new URLRequest("http://5ivestar.org/proxy/http://files.getdropbox.com/u/271700/gamut_AdobeRGB.txt"));	
			loader.load(new URLRequest("http://blog-imgs-49.fc2.com/c/h/o/chocolife/gamut_AdobeRGB.txt"));	
			
			file.addEventListener(Event.SELECT, selectHandler);
			file.addEventListener(Event.COMPLETE, onFileLoad);
			
			stage.addEventListener(Event.ENTER_FRAME, enterFarme);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, downHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, upHandler);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, moveHandler);
			
			makeWorld();
		}
		
		
		private function completeHandler(event:Event):void {
			lab_colors = event.target.data.split('\r');
			makeParticles();
		}
		
		
		private function makeParticles():void {
			
			pChips.removeAllParticles();
			
			text1.text = mes1;
			var coordinates:Array = [];
			var rgb:Object = {};
			var xyz:Object = {};
			var plot_color:String;
			
			for (var i:Number = 0; i < lab_colors.length-1; i++) {
				coordinates = lab_colors[i].split('\t');
				xyz = lab2xyz(coordinates[2], coordinates[0], coordinates[1]);
				rgb = xyz2rgb(xyz.x, xyz.y, xyz.z);
				plot_color = toHexRgb(rgb);
				var particleMat:ParticleMaterial = new ParticleMaterial(parseInt(plot_color), 1)
				var pt:Particle = new Particle(particleMat, 5, coordinates[0]*5, (coordinates[2]-50)*5, coordinates[1]*5);
				pChips.addParticle(pt);
			}
			
		}
		
		
		private function enterFarme(e:Event):void {						  
				// easing: (target - current) * deceleration
				rot += (targetRot - rot) * 0.05;
				pitch += (targetPitch - pitch) * 0.05;
				
				pitch = Math.max(pitch, -90);
				pitch = Math.min(pitch, 90);
				
				world.camera.x = 1000 * Math.sin(rot * Math.PI / 180);
				world.camera.z = 1000 * Math.cos(rot * Math.PI / 180);
				world.camera.y = 1000 * Math.sin(pitch * Math.PI / 180);
				//rot += 1.5;
			}
	
	
		private function downHandler(e:MouseEvent):void {
			isMouseDown = true;
			oldX = mouseX;
			oldY = mouseY;
		}
		
	
		private function upHandler(e:MouseEvent):void {
			isMouseDown = false;
		}
		
	
		private function moveHandler(e:MouseEvent):void {
			if(isMouseDown){
				var dx:Number = e.stageX - oldX;
				var dy:Number = e.stageY - oldY;
				
				targetRot += dx * 0.5;
				targetPitch += dy * 0.5;
				
				oldX = e.stageX;
				oldY = e.stageY;
			}
		}
		
		
		private function makeWorld():void {
			
			text1.addEventListener(MouseEvent.CLICK, onClickLoadButton);
			text1.addEventListener(MouseEvent.MOUSE_OVER, onOverLoadButton);
			text1.addEventListener(MouseEvent.MOUSE_OUT, onOutLoadButton);
			text1.type = TextFieldType.DYNAMIC;
			text1.width = 150;
			text1.height = 30;
			text1.x = 350;
			text1.y = 350;
			text1.textColor = 0xFFFFFF;
			text1.autoSize = TextFieldAutoSize.CENTER;
			text1.border = true;
			text1.borderColor = 0xFFFFFF;
			text1.text = '...Loading';
			addChild(text1);
		
			var line_mat = new WireframeMaterial(0xAAAAAA);
			line_mat.doubleSided = true;	
			var line_a = new Plane(line_mat, 1, 1000, 1, 1);
			world.scene.addChild(line_a);
			line_a.y = -250;
			line_a.rotationZ = 90;
			var line_b = new Plane(line_mat, 1, 1000, 1, 1);
			world.scene.addChild(line_b);
			line_b.y = -250;
			line_b.rotationX = 90;
			world.scene.addChild(pChips);
		
		}
		
		
		private function onOverLoadButton(e:Event):void {
			Mouse.cursor = flash.ui.MouseCursor.BUTTON;
		}
		
		private function onOutLoadButton(e:Event):void {
			Mouse.cursor = flash.ui.MouseCursor.ARROW;
		}
		
		
		private function onClickLoadButton(e:Event):void {
			file.browse();
		}
		
		
		private function selectHandler(e:Event):void {
			file.load();
			text1.text = '...Loading';
		}
		
		private function onFileLoad(e:Event):void {
			targetRot = 180;
			targetPitch = 0;
			lab_colors = file.data.toString().split('\r');
			text1.text = mes1;
			makeParticles();
		}
		
		private function toHexRgb(rgb:Object):String {
			var r:String = rgb.r.toString(16);
			var g:String = rgb.g.toString(16);
			var b:String = rgb.b.toString(16);
			if (r.length == 1) r = '0' + r;
			if (g.length == 1) g = '0' + g;
			if (b.length == 1) b = '0' + b;
			var ret:String = '0x' + r + g + b;
			return ret;
		}
		
		
		private function lab2xyz( l:Number, a:Number, b:Number ):Object {
			const REF_X:Number = 95.047; // Observer= 2digrees Illuminant= D65
			const REF_Y:Number = 100.000; 
			const REF_Z:Number = 108.883; 
			var y:Number = (l + 16) / 116;
			var x:Number = a / 500 + y;
			var z:Number = y - b / 200;
			if ( Math.pow( y , 3 ) > 0.008856 ) { y = Math.pow( y , 3 ); }
			else { y = ( y - 16 / 116 ) / 7.787; }
			if ( Math.pow( x , 3 ) > 0.008856 ) { x = Math.pow( x , 3 ); }
			else { x = ( x - 16 / 116 ) / 7.787; }
			if ( Math.pow( z , 3 ) > 0.008856 ) { z = Math.pow( z , 3 ); }
			else { z = ( z - 16 / 116 ) / 7.787; }
			var xyz:Object = {x:0, y:0, z:0};
			xyz.x = REF_X * x;  
			xyz.y = REF_Y * y;
			xyz.z = REF_Z * z;
		 
			return xyz;
		}
		
		
		private function xyz2rgb(X:Number, Y:Number, Z:Number):Object {
			var x:Number = X / 100;        
			var y:Number = Y / 100;        
			var z:Number = Z / 100;        
			var r:Number = x * 3.2406 + y * -1.5372 + z * -0.4986;
			var g:Number = x * -0.9689 + y * 1.8758 + z * 0.0415;
			var b:Number = x * 0.0557 + y * -0.2040 + z * 1.0570;
		 
			if ( r > 0.0031308 ) { r = 1.055 * Math.pow( r , ( 1 / 2.4 ) ) - 0.055; }
			else { r = 12.92 * r; }
			if ( g > 0.0031308 ) { g = 1.055 * Math.pow( g , ( 1 / 2.4 ) ) - 0.055; }
			else { g = 12.92 * g; }
			if ( b > 0.0031308 ) { b = 1.055 * Math.pow( b , ( 1 / 2.4 ) ) - 0.055; }
			else { b = 12.92 * b; }
			var rgb:Object = {r:0, g:0, b:0}
			var tmp_r = Math.min(r*255, 255);
			var tmp_g = Math.min(g*255, 255);
			var tmp_b = Math.min(b*255, 255);
			rgb.r = Math.max(tmp_r, 0);
			rgb.g = Math.max(tmp_g, 0);
			rgb.b = Math.max(tmp_b, 0);
			return rgb;
		}
	
	}
}
