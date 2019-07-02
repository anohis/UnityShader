# Unity Shader
* 需要更系統的管理

## GW2GS
嘗試模擬GW2的武器Twilight效果
![image](https://github.com/anohis/UnityShader/blob/master/Image/GW2GS.jpg)

## Block
物體方塊化後變成光束消失(或者倒著演出)
* 缺少對於物體原有material的融合方式
* 方塊化的shader會產生很多重複的triangle

## Blur
* 有問題

## DOF
常見的實現方式會讓具有相同深度的物體清晰  
所以嘗試改進成能只讓目標周圍清晰
* 算法有問題，某些角度會模糊/清晰

## Dissolving
目標周圍的物體溶解
* 算法能再改進

## Ghost
殘影
* 一個殘影=一個Gameobject很浪費

## RimLight
中間透明
* 在螢幕邊緣的物體，透明區域會偏移，因為角度是以畫面正中心當視線起始點

## CircleRange
圓形範圍的預覽，可調整角度
* 距離目前已Scale來調整
* 角度過大時，邊框線會變細
