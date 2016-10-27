//
//  Context.swift
//  Silica
//
//  Created by Alsey Coleman Miller on 5/8/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#if os(Linux)
	import Glibc
#endif

import Cairo
import CCairo

public final class Context {
	
	// MARK: - Properties
	
	public let surface: Cairo.Surface
	
	public let size: Size
	
	public var textMatrix = AffineTransform.identity
	
	// MARK: - Private Properties
	
	private let internalContext: Cairo.Context
	
	private var internalState: State = State()
	
	// MARK: - Initialization
	
	public init(surface: Cairo.Surface, size: Size) throws {
		
		let context = Cairo.Context(surface: surface)
		
		if let error = context.status.toError() {
			
			throw error
		}
		
		// Cairo defaults to line width 2.0
		context.lineWidth = 1.0
		
		self.size = size
		self.internalContext = context
		self.surface = surface
	}
	
	// MARK: - Accessors
	
	/// Returns the current transformation matrix.
	public var currentTransform: AffineTransform {
		
		return AffineTransform(cairo: internalContext.matrix)
	}
	
	public var currentPoint: Point? {
		
		guard let point = internalContext.currentPoint
			else { return nil }
		
		return Point(x: point.x, y: point.y)
	}
	
	public var shouldAntialias: Bool {
		
		get { return internalContext.antialias != CAIRO_ANTIALIAS_NONE }
		
		set { internalContext.antialias = newValue ? CAIRO_ANTIALIAS_DEFAULT : CAIRO_ANTIALIAS_NONE }
	}
	
	public var lineWidth: Double {
		
		get { return internalContext.lineWidth }
		
		set { internalContext.lineWidth = newValue }
	}
	
	public var lineJoin: LineJoin {
		
		get { return LineJoin(cairo: internalContext.lineJoin) }
		
		set { internalContext.lineJoin = newValue.toCairo() }
	}
	
	public var lineCap: LineCap {
		
		get { return LineCap(cairo: internalContext.lineCap) }
		
		set { internalContext.lineCap = newValue.toCairo() }
	}
	
	public var miterLimit: Double {
		
		get { return internalContext.miterLimit }
		
		set { internalContext.miterLimit = newValue }
	}
	
	public var lineDash: (phase: Double, lengths: [Double]) {
		
		get { return internalContext.lineDash }
		
		set { internalContext.lineDash = newValue }
	}
	
	public var tolerance: Double {
		
		get { return internalContext.tolerance }
		
		set { internalContext.tolerance = newValue }
	}
	
	/// Returns a `Path` built from the current path information in the graphics context.
	public var path: Path {
		
		var path = Path()
		
		let cairoPath = internalContext.copyPath()
		
		var index = 0
		
		while index < cairoPath.count {
			
			let header = cairoPath[index].header
			
			let length = Int(header.length)
			
			let data = Array(cairoPath.data[index + 1 ..< length])
			
			let element: Path.Element
			
			switch header.type {
				
			case CAIRO_PATH_MOVE_TO:
				
				let point = Point(x: data[0].point.x, y: data[0].point.y)
				
				element = Path.Element.moveToPoint(point)
				
			case CAIRO_PATH_LINE_TO:
				
				let point = Point(x: data[0].point.x, y: data[0].point.y)
				
				element = Path.Element.addLineToPoint(point)
				
			case CAIRO_PATH_CURVE_TO:
				
				let control1 = Point(x: data[0].point.x, y: data[0].point.y)
				let control2 = Point(x: data[1].point.x, y: data[1].point.y)
				let destination = Point(x: data[2].point.x, y: data[2].point.y)
				
				element = Path.Element.addCurveToPoint(control1, control2, destination)
				
			case CAIRO_PATH_CLOSE_PATH:
				
				element = Path.Element.closeSubpath
				
			default: fatalError("Unknown Cairo Path data: \(header.type.rawValue)")
			}
			
			path.elements.append(element)
			
			// increment
			index += length
		}
		
		return path
	}
	
	public var fillColor: Color {
		
		get { return internalState.fill?.color ?? Color.black }
		
		set { internalState.fill = (newValue, Cairo.Pattern(color: newValue)) }
	}
	
	public var strokeColor: Color {
		
		get { return internalState.stroke?.color ?? Color.black }
		
		set { internalState.stroke = (newValue, Cairo.Pattern(color: newValue)) }
	}
	
	public var alpha: Double {
		
		get { return internalState.alpha }
		
		set {
			
			// store new value
			internalState.alpha = newValue
			
			// update stroke
			if var stroke = internalState.stroke {
				
				stroke.color.alpha = newValue
				stroke.pattern = Pattern(color: stroke.color)
				
				internalState.stroke = stroke
			}
			
			// update fill
			if var fill = internalState.fill {
				
				fill.color.alpha = newValue
				fill.pattern = Pattern(color: fill.color)
				
				internalState.fill = fill
			}
		}
	}
	
	public var fontSize: Double {
		
		@inline(__always)
		get { return internalState.fontSize }
		
		set { internalState.fontSize = newValue }
	}
	
	public var characterSpacing: Double {
		
		get { return internalState.characterSpacing }
		
		set { internalState.characterSpacing = newValue }
	}
	
	public var textDrawingMode: TextDrawingMode {
		
		get { return internalState.textMode }
		
		set { internalState.textMode = newValue }
	}
	
	public var textPosition: Point {
		
		get { return Point(x: textMatrix.t.x, y: textMatrix.t.y) }
		
		set { textMatrix.t = (newValue.x, newValue.y) }
	}
	
	// MARK: - Methods
	
	// MARK: Defining Pages
	
	public func beginPage() {
		
		internalContext.copyPage()
	}
	
	public func endPage() {
		
		internalContext.showPage()
	}
	
	// MARK: Transforming the Coordinate Space
	
	public func scale(x: Double, y: Double) {
		
		internalContext.scale(x: x, y: y)
	}
	
	public func translate(x: Double, y: Double) {
		
		internalContext.translate(x: x, y: y)
	}
	
	public func rotate(_ angle: Double) {
		
		internalContext.rotate(angle)
	}
	
	public func transform(_ transform: AffineTransform) {
		
		internalContext.transform(transform.toCairo())
	}
	
	// MARK: Saving and Restoring the Graphics State
	
	public func save() throws {
		
		internalContext.save()
		
		if let error = internalContext.status.toError() {
			
			throw error
		}
		
		let newState = internalState.copy
		
		newState.next = internalState
		
		internalState = newState
	}
	
	public func restore() throws {
		
		guard let restoredState = internalState.next
			else { throw CAIRO_STATUS_INVALID_RESTORE.toError()! }
		
		internalContext.restore()
		
		if let error = internalContext.status.toError() {
			
			throw error
		}
		
		// success
		
		internalState = restoredState
	}
	
	// MARK: Setting Graphics State Attributes
	
	public func setShadow(offset: Size, radius: Double, color: Color) {
		
		let colorPattern = Pattern(color: color)
		
		internalState.shadow = (offset: offset, radius: radius, color: color, pattern: colorPattern)
	}
	
	// MARK: Constructing Paths
	
	public func beginPath() {
		
		internalContext.newPath()
	}
	
	public func closePath() {
		
		internalContext.closePath()
	}
	
	public func move(to point: Point) {
		
		internalContext.move(to: (x: point.x, y: point.y))
	}
	
	public func line(to point: Point) {
		
		internalContext.line(to: (x: point.x, y: point.y))
	}
	
	public func curve(to points: (Point, Point), end: Point) {
		
		internalContext.curve(to: ((x: points.0.x, y: points.0.y), (x: points.1.x, y: points.1.y), (x: end.x, y: end.y)))
	}
	
	public func quadCurve(to point: Point, end: Point) {
		
		let currentPoint = self.currentPoint ?? Point()
		
		let first = Point(x: (currentPoint.x / 3.0) + (2.0 * point.x / 3.0),
		                  y: (currentPoint.y / 3.0) + (2.0 * point.y / 3.0))
		
		let second = Point(x: (2.0 * currentPoint.x / 3.0) + (end.x / 3.0),
		                   y: (2.0 * currentPoint.y / 3.0) + (end.y / 3.0))
		
		curve(to: (first, second), end: end)
	}
	
	public func arc(center: Point, radius: Double, angle: (start: Double, end: Double), negative: Bool) {
		
		internalContext.addArc((x: center.x, y: center.y), radius: radius, angle: angle, negative: negative)
	}
	
	public func arc(to points: (Point, Point), radius: Double) {
		
		let currentPoint = self.currentPoint ?? Point()
		
		// arguments
		let x0 = currentPoint.x
		let y0 = currentPoint.y
		let x1 = points.0.x
		let y1 = points.0.y
		let x2 = points.1.x
		let y2 = points.1.y
		
		// calculated
		let dx0 = x0 - x1
		let dy0 = y0 - y1
		let dx2 = x2 - x1
		let dy2 = y2 - y1
		let xl0 = sqrt((dx0 * dx0) + (dy0 * dy0))
		
		guard xl0 != 0 else { return }
		
		let xl2 = sqrt((dx2 * dx2) + (dy2 * dy2))
		let san = (dx2 * dy0) - (dx0 * dy2)
		
		guard san != 0 else {
			
			line(to: points.0)
			return
		}
		
		let n0x: Double
		let n0y: Double
		let n2x: Double
		let n2y: Double
		
		if san < 0 {
			n0x = -dy0 / xl0
			n0y = dx0 / xl0
			n2x = dy2 / xl2
			n2y = -dx2 / xl2
			
		} else {
			n0x = dy0 / xl0
			n0y = -dx0 / xl0
			n2x = -dy2 / xl2
			n2y = dx2 / xl2
		}
		
		let t = (dx2*n2y - dx2*n0y - dy2*n2x + dy2*n0x) / san
		
		let center = Point(x: x1 + radius * (t * dx0 + n0x), y: y1 + radius * (t * dy0 + n0y))
		let angle = (start: atan2(-n0y, -n0x), end: atan2(-n2y, -n2x))
		
		self.arc(center: center, radius: radius, angle: angle, negative: (san < 0))
	}
	
	public func add(rect: Rect) {
		
		internalContext.addRectangle(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height)
	}
	
	public func add(path: Path) {
		
		for element in path.elements {
			
			switch element {
				
			case let .moveToPoint(point): move(to: point)
				
			case let .addLineToPoint(point): line(to: point)
				
			case let .addQuadCurveToPoint(control, destination): quadCurve(to: control, end: destination)
				
			case let .addCurveToPoint(control1, control2, destination): curve(to: (control1, control2), end: destination)
				
			case .closeSubpath: closePath()
			}
		}
	}
	
	// MARK: - Painting Paths
	
	/// Paints a line along the current path.
	public func stroke() throws {
		
		if internalState.shadow != nil {
			
			startShadow()
		}
		
		internalContext.source = internalState.stroke?.pattern ?? DefaultPattern
		
		internalContext.stroke()
		
		if internalState.shadow != nil {
			
			endShadow()
		}
		
		if let error = internalContext.status.toError() {
			
			throw error
		}
	}
	
	public func fill(evenOdd: Bool = false) throws {
		
		try fillPath(evenOdd: evenOdd, preserve: false)
	}
	
	public func clear() throws {
		
		internalContext.source = internalState.fill?.pattern ?? DefaultPattern
		
		internalContext.clip()
		internalContext.clipPreserve()
		
		if let error = internalContext.status.toError() {
			
			throw error
		}
	}
	
	public func draw(_ mode: DrawingMode = DrawingMode()) throws {
		
		switch mode {
		case .fill: try fillPath(evenOdd: false, preserve: false)
		case .evenOddFill: try fillPath(evenOdd: true, preserve: false)
		case .fillStroke: try fillPath(evenOdd: false, preserve: true)
		case .evenOddFillStroke: try fillPath(evenOdd: true, preserve: true)
		case .stroke: try stroke()
		}
	}
	
	public func clip(evenOdd: Bool = false) {
		
		if evenOdd {
			
			internalContext.fillRule = CAIRO_FILL_RULE_EVEN_ODD
		}
		
		internalContext.clip()
		
		if evenOdd {
			
			internalContext.fillRule = CAIRO_FILL_RULE_WINDING
		}
	}
	
	@inline(__always)
	public func clip(to rect: Rect) {
		
		beginPath()
		add(rect: rect)
		clip()
	}
	
	// MARK: - Using Transparency Layers
	
	public func beginTransparencyLayer(rect: Rect? = nil) throws {
		
		// in case we clip (for the rect)
		internalContext.save()
		
		if let error = internalContext.status.toError() {
			
			throw error
		}
		
		if let rect = rect {
			
			internalContext.newPath()
			add(rect: rect)
			internalContext.clip()
		}
		
		try save()
		alpha = 1.0
		internalState.shadow = nil
		
		internalContext.pushGroup()
	}
	
	public func endTransparencyLayer() throws {
		
		let group = internalContext.popGroup()
		
		// undo change to alpha and shadow state
		try restore()
		
		// paint contents
		internalContext.source = group
		internalContext.paint(internalState.alpha)
		
		// undo clipping (if any)
		internalContext.restore()
		
		if let error = internalContext.status.toError() {
			
			throw error
		}
	}
	
	// MARK: - Drawing an Image to a Graphics Context
	
	/// Draws an image into a graphics context.
	public func draw(image: Image) {
		
		fatalError("Not implemented")
	}
	
	// MARK: - Drawing Text
	
	public func setFont(_ font: Font) {
		
		internalContext.fontFace = font.scaledFont.face
		internalState.font = font
	}
	
	/// Uses the Cairo toy text API.
	public func show(toyText text: String) {
		
		let oldPoint = internalContext.currentPoint
		
		internalContext.move(to: (0, 0))
		
		// calculate text matrix
		
		var cairoTextMatrix = Matrix.identity
		
		cairoTextMatrix.scale(x: fontSize, y: fontSize)
		
		cairoTextMatrix.multiply(a: cairoTextMatrix, b: textMatrix.toCairo())
		
		internalContext.setFont(cairoTextMatrix)
		
		internalContext.source = internalState.fill?.pattern ?? DefaultPattern
		
		internalContext.show(text)
		
		let distance = internalContext.currentPoint ?? (0, 0)
		
		textPosition = Point(x: textPosition.x + distance.x, y: textPosition.y + distance.y)
		
		if let oldPoint = oldPoint {
			
			internalContext.move(to: oldPoint)
			
		} else {
			
			internalContext.newPath()
		}
	}
	
	//@inline(__always)
	public func show(text: String) {
		
		guard let font = internalState.font?.scaledFont,
			fontSize > 0.0 && text.isEmpty == false
			else { return }
		
		let glyphs = text.unicodeScalars.map { font[UInt($0.value)] }
		
		show(glyphs: glyphs)
	}
	
	public func show(glyphs: [FontIndex]) {
		
		guard let font = internalState.font,
			fontSize > 0.0 && glyphs.isEmpty == false
			else { return }
		
		let advances = font.advances(for: glyphs, fontSize: fontSize, textMatrix: textMatrix, characterSpacing: characterSpacing)
		// workaround for merge crashing swift compiler for v >3.0.1GM
		//show(glyphs: unsafeBitCast(glyphs.merge(advances), to: [(glyph: FontIndex, advance: Size)].self))
		show(glyphs: unsafeBitCast(glyphs.indexedMap({($0.1, advances[$0.0])}), to: [(glyph: FontIndex, advance: Size)].self))
	}
	
	public func show(glyphs glyphAdvances: [(glyph: FontIndex, advance: Size)]) {
		
		guard let font = internalState.font,
			fontSize > 0.0 && glyphAdvances.isEmpty == false
			else { return }
		
		let advances = glyphAdvances.map { $0.advance }
		let glyphs = glyphAdvances.map { $0.glyph }
		let positions = font.positions(for: advances, textMatrix: textMatrix)
		
		// render
		// workaround for merge crashing swift compiler for v >3.0.1GM

		//show(glyphs: unsafeBitCast(glyphs.merge(positions), to: [(glyph: FontIndex, position: Point)].self))
		show(glyphs: unsafeBitCast(glyphs.indexedMap({($0.1, positions[$0.0])}), to: [(glyph: FontIndex, position: Point)].self))
		
		// advance text position
		advances.forEach {
			textPosition.x += $0.width
			textPosition.y += $0.height
		}
	}
	
	public func show(glyphs glyphPositions: [(glyph: FontIndex, position: Point)]) {
		
		guard let font = internalState.font?.scaledFont,
			fontSize > 0.0 && glyphPositions.isEmpty == false
			else { return }
		
		// actual rendering
		
		let cairoGlyphs: [cairo_glyph_t] = glyphPositions.indexedMap { (index, element) in
			
			var cairoGlyph = cairo_glyph_t()
			
			cairoGlyph.index = UInt(element.glyph)
			
			let userSpacePoint = element.position.applying(textMatrix)
			
			cairoGlyph.x = userSpacePoint.x
			
			cairoGlyph.y = userSpacePoint.y
			
			return cairoGlyph
		}
		
		var cairoTextMatrix = Matrix.identity
		
		cairoTextMatrix.scale(x: fontSize, y: fontSize)
		
		let ascender = (Double(font.ascent) * fontSize) / Double(font.unitsPerEm)
		
		let silicaTextMatrix = Matrix(a: textMatrix.a, b: textMatrix.b, c: textMatrix.c, d: textMatrix.d, t: (0, ascender))
		
		cairoTextMatrix.multiply(a: cairoTextMatrix, b: silicaTextMatrix)
		
		internalContext.setFont(cairoTextMatrix)
		
		internalContext.source = internalState.fill?.pattern ?? DefaultPattern
		
		// show glyphs
		cairoGlyphs.forEach { internalContext.show(($0)) }
	}
	
	// MARK: - Private Functions
	
	private func fillPath(evenOdd: Bool, preserve: Bool) throws {
		
		if internalState.shadow != nil {
			
			startShadow()
		}
		
		internalContext.source = internalState.fill?.pattern ?? DefaultPattern
		
		internalContext.fillRule = evenOdd ? CAIRO_FILL_RULE_EVEN_ODD : CAIRO_FILL_RULE_WINDING
		
		internalContext.fillPreserve()
		
		if preserve == false {
			
			internalContext.newPath()
		}
		
		if internalState.shadow != nil {
			
			endShadow()
		}
		
		if let error = internalContext.status.toError() {
			
			throw error
		}
	}
	
	private func startShadow() {
		
		internalContext.pushGroup()
	}
	
	private func endShadow() {
		
		let pattern = internalContext.popGroup()
		
		internalContext.save()
		
		let radius = internalState.shadow!.radius
		
		let alphaSurface = Surface(format: .a8,
		                           width: Int(ceil(size.width + 2 * radius)),
		                           height: Int(ceil(size.height + 2 * radius)))
		
		let alphaContext = Cairo.Context(surface: alphaSurface)
		
		alphaContext.source = pattern
		
		alphaContext.paint()
		
		alphaSurface.flush()
		
		internalContext.source = internalState.shadow!.pattern
		
		internalContext.mask(alphaSurface, at: (internalState.shadow!.offset.width, internalState.shadow!.offset.height))
		
		// draw content
		internalContext.source = pattern
		internalContext.paint()
		
		internalContext.restore()
	}
}

// MARK: - Private

/// Default black pattern
fileprivate let DefaultPattern = Cairo.Pattern(color: (red: 0, green: 0, blue: 0))

fileprivate extension Context {
	
	/// To save non-Cairo state variables
	fileprivate final class State {
		
		var next: State?
		var alpha: Double = 1.0
		var fill: (color: Color, pattern: Cairo.Pattern)?
		var stroke: (color: Color, pattern: Cairo.Pattern)?
		var shadow: (offset: Size, radius: Double, color: Color, pattern: Cairo.Pattern)?
		var font: Font?
		var fontSize: Double = 0.0
		var characterSpacing: Double = 0.0
		var textMode = TextDrawingMode()
		
		init() { }
		
		var copy: State {
			
			let copy = State()
			
			copy.next = next
			copy.alpha = alpha
			copy.fill = fill
			copy.stroke = stroke
			copy.shadow = shadow
			copy.font = font
			copy.fontSize = fontSize
			copy.characterSpacing = characterSpacing
			copy.textMode = textMode
			
			return copy
		}
	}
}

// MARK: - Internal Extensions

internal extension Collection {
	
	func indexedMap<T>(_ transform: (Index, Iterator.Element) throws -> T) rethrows -> [T] {
		
		let count: Int = numericCast(self.count)
		if count == 0 {
			return []
		}
		
		var result = ContiguousArray<T>()
		result.reserveCapacity(count)
		
		var i = self.startIndex
		
		for _ in 0..<count {
			result.append(try transform(i, self[i]))
			formIndex(after: &i)
		}
		return Array(result)
	}
	
	//@inline(__always)
	/*func merge<C: Collection, T>
		(_ other: C) -> [(Iterator.Element, T)]
		where C.Iterator.Element == T, C.IndexDistance == IndexDistance, C.Index == Index {
			
			precondition(self.count == other.count, "The collection to merge must be of the same size")
			
			//return self.indexedMap { ($0.1, other[$0.0]) }
	}*/
	
}
