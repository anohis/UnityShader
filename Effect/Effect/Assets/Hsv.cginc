#ifndef HSV
#define HSV

half _Brightness;
half _Saturation;
half _Contrast;

fixed3 GetColor(fixed3 color)
{
	fixed3 finalColor = color * _Brightness;
	fixed gray = 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
	fixed3 grayColor = fixed3(gray, gray, gray);
	finalColor = lerp(grayColor, finalColor, _Saturation);
	fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
	finalColor = lerp(avgColor, finalColor, _Contrast);
	return finalColor;
}
#endif