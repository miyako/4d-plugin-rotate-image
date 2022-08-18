$event:=FORM Event:C1606

Case of 
	: ($event.code=On Load:K2:1)
		
		var $image : Picture
		
		Form:C1466.file:=Folder:C1567(fk resources folder:K87:11).file("sample.tiff")
		
		READ PICTURE FILE:C678(Form:C1466.file.platformPath; $image)
		
		Form:C1466.original:=$image
		Form:C1466.image:=$image
		Form:C1466.angle:=-1  //READ PICTURE FILE ignores orientation
		Form:C1466.format:=".jpg"
		Form:C1466.size:=0
		
		var $orientation : Integer
		
		GET PICTURE METADATA:C1122($image; TIFF orientation:K68:146; $orientation)
		
		Form:C1466.orientation:=$orientation
		
		OBJECT Get pointer:C1124(Object named:K67:5; "r:0")->:=0
		
	: ($event.code=On Clicked:K2:4)
		
		If ($event.objectName="r:@")
			
			Form:C1466.rotate:=Num:C11($event.objectName)
			
			If (Form:C1466.angle#Form:C1466.rotate)
				
				Form:C1466.angle:=Form:C1466.rotate
				
				PICTURE TO BLOB:C692(Form:C1466.original; $data; Form:C1466.file.extension)
				
				$status:=Rotate image($data; Form:C1466.rotate; Form:C1466.format)
				
				If ($status.success)
					Form:C1466.image:=$status.image
					Form:C1466.size:=Picture size:C356(Form:C1466.image)
					Form:C1466.time:=$status.time
				End if 
				
			End if 
			
		End if 
		
End case 