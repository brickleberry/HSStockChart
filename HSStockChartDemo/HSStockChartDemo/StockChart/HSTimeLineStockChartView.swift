//
//  TimeLineStockChartView.swift
//  MyStockChartDemo
//
//  Created by Hanson on 16/8/16.
//  Copyright © 2016年 hanson. All rights reserved.
//

import UIKit

class HSTimeLineStockChartView: HSBaseStockChartView {
    
    var candleCoordsScale : CGFloat = 0
    var volumeCoordsScale : CGFloat = 0
    
    var endPointShowEnabled = true
    var isDrawAvgLine = true
    
    var countOfTimes = 242
    var offsetMaxPrice : CGFloat = 0
    var showFiveDayLabel = false

    var longPressGesture : UILongPressGestureRecognizer{
        return UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGestureAction(_:)))
    }
    
    var volumeWidth: CGFloat = 0
    
    var dataSet : TimeLineDataSet? {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    
    //MARK: - 构造方法
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addGestureRecognizer(longPressGesture)
    }
    
    override init(frame: CGRect, uperChartHeightScale: CGFloat, topOffSet: CGFloat, leftOffSet: CGFloat, bottomOffSet: CGFloat, rightOffSet: CGFloat) {
        
        super.init(frame: frame, uperChartHeightScale: uperChartHeightScale, topOffSet: topOffSet, leftOffSet: leftOffSet, bottomOffSet: bottomOffSet, rightOffSet: rightOffSet)
        
        self.addGestureRecognizer(longPressGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.addGestureRecognizer(longPressGesture)
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        if let data = self.dataSet?.data where data.count > 0 {
            let context = UIGraphicsGetCurrentContext()
            setCurrentDataMaxAndMin()
            drawGridBackground(context!, rect: rect)
            drawTimeLine(context!, data: data)
            drawTimeLabelInXAxis(context!)
            drawPriceLabel(context!)
            drawRatioLabel(context!)
            
        } else {
            // to show error page
        }
    }
    
    
    //MARK: - Function
    
    func setCurrentDataMaxAndMin() {
        if let data = self.dataSet?.data where data.count > 0{
            self.maxPrice = -9999
            self.minPrice = 9999
            self.maxRatio = -9999
            self.minRatio = 9999
            self.maxVolume = -9999
            self.offsetMaxPrice = -9999
            
            for i in 0 ..< data.count {
                let entity = data[i]
                self.offsetMaxPrice = self.offsetMaxPrice > fabs(entity.price - entity.preClosePx) ? self.offsetMaxPrice : fabs(entity.price - entity.preClosePx)
                
                self.maxVolume = self.maxVolume > entity.volume ? self.maxVolume : entity.volume
                
                self.maxRatio = self.maxRatio > fabs(entity.rate) ? self.maxRatio : entity.rate
                self.minRatio = self.minRatio < fabs(entity.rate) ? self.minRatio : entity.rate
            }
            
            self.maxPrice = data.first!.preClosePx + self.offsetMaxPrice
            self.minPrice = data.first!.preClosePx - self.offsetMaxPrice
            
            /*
             if self.minPrice >= self.maxPrice{
             self.maxPrice = self.maxPrice * 1.02
             self.minPrice = self.minPrice * 0.98
             } */
            
            for i in 0 ..< data.count {
                let entity = data[i]
                entity.avgPirce = entity.avgPirce < self.minPrice ? self.minPrice : entity.avgPirce
                entity.avgPirce = entity.avgPirce > self.maxPrice ? self.maxPrice : entity.avgPirce
            }
        }
    }
    
    //画图表边框
    override func drawGridBackground(context: CGContextRef, rect: CGRect) {
        super.drawGridBackground(context, rect: rect)
        
        if showFiveDayLabel {
            //五日分时图的四条竖线
            let width = self.contentWidth / 5
            for i in 1 ..< 5 {
                let lineX = self.contentLeft + width * CGFloat(i)
                let startPoint = CGPointMake(lineX, uperChartBottom)
                let stopPoint = CGPointMake(lineX, contentTop)
                self.drawline(context, startPoint: startPoint, stopPoint: stopPoint, color: borderColor, lineWidth: borderWidth / 2.0)
            }
            
        } else {
            //分时线的中间竖线
            let startPoint = CGPointMake(contentWidth / 2.0 + contentLeft, contentTop)
            let stopPoint = CGPointMake(contentWidth / 2.0 + contentLeft, uperChartHeight +  contentTop)
            self.drawline(context, startPoint: startPoint, stopPoint: stopPoint, color: borderColor, lineWidth: borderWidth / 2.0)
        }
    }
    
    //画横坐标的时间标签
    func drawTimeLabelInXAxis(context:CGContextRef) {
        
        if let d = self.dataSet?.days where showFiveDayLabel {
            let width = self.contentWidth / 5
            for (index, day) in d.enumerate() {
                let drawAttributes = self.xAxisLabelAttribute
                let startTimeAttributedString = NSMutableAttributedString(string: day, attributes: drawAttributes)
                let sizestartTimeAttributedString = startTimeAttributedString.size()
                let labelX = self.contentLeft + (width - sizestartTimeAttributedString.width) / 2 + width * CGFloat(index)
                self.drawLabel(context,
                               attributesText: startTimeAttributedString,
                               rect: CGRectMake(labelX, uperChartBottom, sizestartTimeAttributedString.width, sizestartTimeAttributedString.height))
            }
            
        } else {
            let drawAttributes = self.xAxisLabelAttribute
            let startTimeAttributedString = NSMutableAttributedString(string: "9:30", attributes: drawAttributes)
            let sizestartTimeAttributedString = startTimeAttributedString.size()
            self.drawLabel(context, attributesText: startTimeAttributedString, rect: CGRectMake(self.contentLeft, uperChartBottom, sizestartTimeAttributedString.width, sizestartTimeAttributedString.height))
            
            let midTimeAttStr = NSMutableAttributedString(string: "11:30/13:00", attributes: drawAttributes)
            let sizeMidTimeAttStr = midTimeAttStr.size()
            self.drawLabel(context, attributesText: midTimeAttStr, rect: CGRectMake(self.contentWidth / 2.0 + self.contentLeft - sizeMidTimeAttStr.width / 2.0, uperChartBottom, sizeMidTimeAttStr.width, sizeMidTimeAttStr.height))
            
            let stopTimeAttStr = NSMutableAttributedString(string: "15:00", attributes: drawAttributes)
            let sizeStopTimeAttStr = stopTimeAttStr.size()
            self.drawLabel(context, attributesText: stopTimeAttStr, rect: CGRectMake(self.contentRight - sizeStopTimeAttStr.width, uperChartBottom, sizeStopTimeAttStr.width, sizeStopTimeAttStr.height))
        }
    }
    
    // 画纵坐标的最高和最低价格标签
    func drawPriceLabel(context:CGContextRef) {        
        let maxPriceStr = self.formatValue(maxPrice)
        let minPriceStr = self.formatValue(minPrice)
        
        self.drawYAxisLabel(context, labelString: maxPriceStr, yAxis: uperChartDrawAreaTop, isLeft: false)
        self.drawYAxisLabel(context, labelString: minPriceStr, yAxis: uperChartDrawAreaBottom, isLeft: false)
    }
    
    // 画比率标签
    func drawRatioLabel(context:CGContextRef){
        let maxRatioStr = self.formatValue(self.maxRatio) + "%"
        let minRatioStr = self.formatValue(self.minRatio) + "%"
        
        self.drawYAxisLabel(context, labelString: maxRatioStr, yAxis: uperChartDrawAreaTop, isLeft: true)
        self.drawYAxisLabel(context, labelString: minRatioStr, yAxis: uperChartDrawAreaBottom, isLeft: true)
    }
    
    // 画分时线，均线，成交量
    func drawTimeLine(context: CGContextRef, data: [TimeLineEntity]){
        CGContextSaveGState(context)

        self.candleCoordsScale = uperChartDrawAreaHeight / (self.maxPrice - self.minPrice)
        self.volumeCoordsScale = (lowerChartHeight - lowerChartDrawAreaMargin) / (self.maxVolume - 0)
        
        let fillPath = CGPathCreateMutable()
        
        if showFiveDayLabel {
            self.volumeWidth = self.contentWidth / CGFloat(data.count)
        } else {
            self.volumeWidth = self.contentWidth / CGFloat(self.countOfTimes)
        }
        
        //画中间的横虚线
        if let temp = data.first {
            //日分时图中间区域线代表昨日的收盘价格，五日分时图的则代表五日内的第一天9点30分的价格
            let price = showFiveDayLabel ? temp.price : temp.preClosePx
            let preClosePriceYaxis = (self.maxPrice - price) * self.candleCoordsScale + self.uperChartDrawAreaTop
            self.drawline(context,
                          startPoint: CGPointMake(contentLeft, preClosePriceYaxis),
                          stopPoint: CGPointMake(contentRight, preClosePriceYaxis),
                          color: borderColor,
                          lineWidth: borderWidth / 2.0,
                          isDashLine: true)
            self.drawYAxisLabel(context, labelString: formatValue(temp.preClosePx), yAxis: preClosePriceYaxis, isLeft: false)
        }
        
        for i in 0 ..< data.count {
            let entity = data[i]
            // 交易量柱之间的间隙 self.volumeWidth/6.0
            let left = (self.volumeWidth * CGFloat(i) + contentLeft) + self.volumeWidth / 6.0
            let candleWidth = self.volumeWidth - self.volumeWidth / 3.0
            let startX = left + candleWidth / 2.0
            var yPrice: CGFloat = 0
            
            var color = self.dataSet!.volumeRiseColor
            
            if i > 0 {
                let previousEntity = data[i - 1]
                let preX: CGFloat = startX - self.volumeWidth
                let previousPrice = (self.maxPrice - previousEntity.price) * self.candleCoordsScale + self.uperChartDrawAreaTop
                yPrice = (self.maxPrice - entity.price) * self.candleCoordsScale + self.uperChartDrawAreaTop
                //画分时线
                self.drawline(context,
                              startPoint: CGPointMake(preX, previousPrice),
                              stopPoint: CGPointMake(startX, yPrice),
                              color: self.dataSet!.priceLineCorlor,
                              lineWidth: self.dataSet!.lineWidth)
                
                if isDrawAvgLine {
                    //画均线
                    let lastYAvg = (self.maxPrice - previousEntity.avgPirce) * self.candleCoordsScale  + self.uperChartDrawAreaTop
                    let yAvg = (self.maxPrice - entity.avgPirce) * self.candleCoordsScale  + self.uperChartDrawAreaTop
                    
                    self.drawline(context, startPoint: CGPointMake(preX, lastYAvg), stopPoint: CGPointMake(startX, yAvg), color: self.dataSet!.avgLineCorlor, lineWidth: self.dataSet!.lineWidth)
                }
                
                //设置成交量的颜色
                if (entity.price > previousEntity.price) {
                    color = self.dataSet!.volumeRiseColor
                }else if (entity.price < previousEntity.price){
                    color = self.dataSet!.volumeFallColor
                }else{
                    color = self.dataSet!.volumeTieColor
                }
                
                //填充渐变颜色
                if 1 == i {
                    CGPathMoveToPoint(fillPath, nil, self.contentLeft, uperChartHeight + self.contentTop)
                    CGPathAddLineToPoint(fillPath, nil, self.contentLeft, previousPrice)
                    CGPathAddLineToPoint(fillPath, nil, preX, previousPrice)
                }else{
                    CGPathAddLineToPoint(fillPath, nil, startX, yPrice)
                }
                if (data.count - 1) == i {
                    CGPathAddLineToPoint(fillPath, nil, startX, yPrice)
                    CGPathAddLineToPoint(fillPath, nil, startX, uperChartHeight + self.contentTop)
                    CGPathCloseSubpath(fillPath)
                }
            }
            
            // 成交量
            let volume = entity.volume * self.volumeCoordsScale
            print("volume " + "\(entity.volume)")
            self.drawColumnRect(context, rect: CGRectMake(left, lowerChartBottom - volume, candleWidth, volume), color: color)
            
            // 最高成交量标签
            if entity.volume == self.maxVolume {
                let y = lowerChartBottom - volume
                self.drawline(context, startPoint: CGPointMake(contentLeft, y), stopPoint: CGPointMake(contentRight, y), color: borderColor, lineWidth: borderWidth / 4.0)
                let maxVolumeStr = self.formatValue(entity.volume)
                self.drawYAxisLabel(context, labelString: maxVolumeStr, yAxis: y, isLeft: false)
            }
            
            //长按显示的十字线
            if self.longPressToHighlightEnabled {
                if (i == self.highlightLineCurrentIndex) {
                    if (i == 0) {
                        yPrice = (self.maxPrice - entity.price) * self.candleCoordsScale  + self.contentTop;
                    }
                    self.drawLongPressHighlight(context,
                                                pricePoint: CGPointMake(startX, yPrice),
                                                volumePoint: CGPointMake(startX, self.contentBottom - volume),
                                                idex: i,
                                                value: entity,
                                                color: self.dataSet!.highlightLineColor,
                                                lineWidth: self.dataSet!.highlightLineWidth)
                }
            }
            
            //结束点高亮显示
            if self.endPointShowEnabled {
                if (i == data.count - 1) {
                    //self.breathingPoint.frame = CGRectMake(startX-4/2, yPrice-4/2, 4, 4)
                }
            }
        }
        
        //填充渐变的颜色
        if self.dataSet!.drawFilledEnabled && data.count > 0 {
            self.drawLinearGradient(context, path: fillPath, alpha: self.dataSet!.fillAlpha, startColor: self.dataSet!.fillStartColor.CGColor, endColor: self.dataSet!.fillStopColor.CGColor)
        }
        
        CGContextRestoreGState(context)
        
    }
    
    func handleLongPressGestureAction(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .Began || recognizer.state == .Changed {
            let  point = recognizer.locationInView(self)
            
            if (point.x > self.contentLeft && point.x < self.contentRight && point.y > self.contentTop && point.y < self.contentBottom) {
                self.longPressToHighlightEnabled = true;
                self.highlightLineCurrentIndex = Int((point.x - self.contentLeft) / self.volumeWidth)
                self.setNeedsDisplay()
            }
            if self.highlightLineCurrentIndex < self.dataSet?.data?.count {
                
            }
        }
        
        if recognizer.state == .Ended {
            self.longPressToHighlightEnabled = false
            self.setNeedsDisplay()
        }
    }
    
}