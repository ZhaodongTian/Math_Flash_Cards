using namespace System.Drawing
using namespace System.Drawing.Imaging
Add-Type -AssemblyName System.Drawing 

## Sets up encoder and Codec for making high quality images
$encParams = [EncoderParameters]::new(1)
$encParams.Param[0] = [EncoderParameter]::new([Encoder]::Quality, 90L);
$Codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-object {$_.MimeType -eq 'image/jpeg'}

function New-NumberBondsImage { 

    param(
        $number = 10
    )

    ## Initialize variables
    $circleDiameter = 650
    $penWidth = 13
    $outlineColor = "black"
    $backgroundColor = "white"
    $imageWidth = 2000
    $imageHeight = 2000

    # Init base image and graphics drawing objects
    #[Image] $Image = [Bitmap]::new($imageWidth, $imageHeight+200) # Width, Height
    $Image = [Bitmap]::new($imageWidth, $imageHeight+400, 'Format24bppRgb') # Width, Height (2200,2200,'Format24bppRgb')
    [Graphics] $DrawingSurface = [Graphics]::FromImage($Image)

    # Initialize an empty region
    $FilledSpace = [Region]::new()
    $FilledSpace.MakeEmpty()# Pens for outlines, brushes for fills
    #$fillBrush = [SolidBrush]::new([Color]::$fillColor)
    $pen = [Pen]::new([Brush] [SolidBrush]::new([Color]::$outlineColor), [double] $PenWidth)
    $fillRegionArea = [Rectangle]::new(0,0,$imageWidth, $imageHeight+400)
    $DrawingSurface.FillRegion([SolidBrush]::new($backgroundColor), $fillRegionArea)
    $NumberFontSize = [Font]::new("Arial Black", 250)
    $brushFg = [System.Drawing.Brushes]::Black 

    $randomWholeNumber = Get-Random -Minimum 2 -Maximum $number
    $randomPartNumber = Get-Random -Minimum 0 -Maximum $randomWholeNumber

    # Create Title
    # Set format of string
    $stringFormat = [StringFormat]::new()
    $stringFormat.LineAlignment = [StringAlignment]::Center
    $stringFormat.Alignment = [StringAlignment]::Center
    $rowSize = 100

    $rectangleBanner = [RectangleF]::new(0, 20, $imageWidth, $rowSize);  #Create rectangle outline for ellipse shape.
    $rectangleAuthor = [RectangleF]::new(0, 30+$rowSize/2, $imageWidth, $rowSize);  #Create rectangle outline for ellipse shape.
    $rectangleFooter = [RectangleF]::new(40, $imageHeight+320, $imageWidth, $rowSize);  #Create rectangle outline for ellipse shape.

    $DrawingSurface.DrawString("Number Bonds 1-$($number)",[Font]::new("Arial Black", 50), $brushFg, $rectangleBanner, $stringFormat) 
    $DrawingSurface.DrawString("By: Jing",[Font]::new("Arial Black", 30), [System.Drawing.Brushes]::Gray, $rectangleAuthor, $stringFormat) 
    $DrawingSurface.DrawString("Visit https://www.teachjing.com for more Flash Cards and other resources.", [Font]::new("Arial Black", 20), [System.Drawing.Brushes]::Gray, $rectangleFooter) 

    $offsetY = 100
    ##### Define Circles #####
    $ellipseArray = @(
        @{
            'Name' = 'Whole'
            'centerCoordinates' = @{
                'coordX' = ($imageWidth/2)
                'coordY' = ($imageHeight/2/2) + $offsetY
            }
            'diameter' = $circleDiameter
            'fillColor' = 'deepskyblue'
            'Number' = $randomWholeNumber
        },
        @{
            'Name' = 'Part'
            'centerCoordinates' = @{
                'coordX' = ($imageWidth/2/2)
                'coordY' = ($imageHeight/2)+($imageHeight/2/2) + $offsetY
            }
            'fillColor' = 'lightcyan'
            'Number' = $randomPartNumber
        },
        @{
            'Name' = 'Part'
            'centerCoordinates' = @{
                'coordX' = ($imageWidth/2)+$($imageWidth/2/2)
                'coordY' = ($imageHeight/2)+($imageHeight/2/2) + $offsetY
            }
            'fillColor' = 'lightcyan'
            'Number' = $randomWholeNumber - $randomPartNumber
        }
    )
       
    $pickNumber = Get-Random -Minimum 0 -Maximum 2
    $ellipseArray[$pickNumber].Number = "?"
    $ellipseArray[$pickNumber].Selected = $true
    $question = "$($ellipseArray[1].Number) and $($ellipseArray[2].Number) makes $($ellipseArray[0].Number)"
    Write-Host "Question: $question"
    $questionArea = [RectangleF]::new(0, $imageHeight+90, $imageWidth, 250);
    $DrawingSurface.DrawString($question, [Font]::new("Arial Black", 90), [System.Drawing.Brushes]::Black, $questionArea, $stringFormat) 
    
    #Draw Lines
    ForEach ($ellipse in $ellipseArray) {
        ## Look for any circles named Whole to set the starting coordinates for the line.
        if ($ellipse.Name -match "Whole") {

            ## Look for any circles named Part to set the 2nd coordinates for the line
            ForEach ($SecondEllipse in $ellipseArray) {
                if ($SecondEllipse.Name -match "Part") {
                    $DrawingSurface.DrawLine($pen, $ellipse.centerCoordinates.coordX, $ellipse.centerCoordinates.coordY, $SecondEllipse.centerCoordinates.coordX, $SecondEllipse.centerCoordinates.coordY)
                    Write-Host "Drawing line from $($ellipse.name) ($($ellipse.centerCoordinates.coordX),$($ellipse.centerCoordinates.coordY)) to $($SecondEllipse.Name) ($($SecondEllipse.centerCoordinates.coordX),$($SecondEllipse.centerCoordinates.coordY))"
                }
            }
        }
    } 

    #Draw Circles
    ForEach ($ellipse in $ellipseArray) {
        $coordX = ($ellipse.centerCoordinates.coordX)-($circleDiameter/2)
        $coordY = ($ellipse.centerCoordinates.coordY)-($circleDiameter/2)
        $fillBrush = [SolidBrush]::new([Color]::$($ellipse.fillColor))
        $fontColor = $brushFg
        if ($ellipse.Number -eq "?") {
            Write-Host $ellipse.Number
            $fontColor = [System.Drawing.Brushes]::Red
        }

        ########## Draw Circle and fill it ##########

        $rectangle = [Rectangle]::new($coordX, $coordY, $circleDiameter, $circleDiameter);  #Create rectangle outline for ellipse shape.
        $DrawingSurface.FillEllipse($fillBrush, $rectangle)  #Fill Ellipse 
        $DrawingSurface.DrawEllipse($pen, $rectangle)  #Draw ellipse to screen.

        ########## Draw string to screen. ##########
        
        $rectangleNumber = [RectangleF]::new($coordX, $coordY, $circleDiameter, $circleDiameter);  #Create rectangle outline for ellipse shape.
        $rectangleTitle = [RectangleF]::new($coordX, $coordY+$circleDiameter, $circleDiameter, 130);  #Create rectangle outline for ellipse shape.

        ## DrawingSurface.DrawString(drawString, drawFont, drawBrush, drawRect, drawFormat);
        $DrawingSurface.DrawString($ellipse.number,$NumberFontSize, $fontColor, $rectangleNumber, $stringFormat) 
        $DrawingSurface.DrawString($ellipse.Name, [Font]::new("Arial Black", 50), [System.Drawing.Brushes]::Gray, $rectangleTitle, $stringFormat) 

        #############################################

        Write-Host "Drawing $($fillColor) Ellipse($($ellipse.Name) at $($coordX), $($coordY) with size of $circleDiameter, Center Coordinates: $($ellipse.CenterCoordinates.coordX), $($ellipse.CenterCoordinates.coordY)"
    } 
    #>
    $exportImage = [System.Drawing.Graphics]::FromImage($Image)
    $exportImage.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $filename = "C:\temp\foo.jpg" 
    
    $Image.Save($filename, $Codec, $encParams)
    $DrawingSurface.Dispose()
    Invoke-Item $filename  

}

New-NumberBondsImage 20

