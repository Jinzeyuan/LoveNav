MIN_POINT_DISTANCE = 14
POINT_HIT_DISTANCE = MIN_POINT_DISTANCE/2

POINT_RADIUS = 4
LINE_WIDTH = 4

WHITE = {255,255,255}
POINT_COLOR = {0,0,255,200}
TRIANGLE_LINE = {green = {0,200,0,100}, red = {200,0,0,100}}
TRIANGLE_FILL = {green = {0,255,0,100}, red = {255,0,0,100}}
POINTER_COLOR = {points = {0,0,255,100}, green = {0,255,0,100},red = {255,0,0,100}, delete = {0,0,0,100}}

SCALING_FACTOR = 0.2
function love.load()
	require "class"
	require "point"
	require "triangle"
	require "saveMesh"
	require "persistence"
	mode = "points"
	love.window.setMode(0,0,{fullscreen = true})
	WINDOW_WIDTH, WINDOW_HEIGHT = love.graphics.getDimensions()
	image = love.graphics.newImage("background.png")
	points = {}
	triangles = {}
	translate = {x=0,y=0}
	scale = 1
	currentTriangle ={}
	love.graphics.setLineWidth( LINE_WIDTH )
	latestPosition = {x=0,y=0}
end

function love.update()
	x, y = love.mouse.getPosition()

	x = x - translate.x
	y = y - translate.y
	x = x / scale
	y = y / scale

	latestPosition = {x=x,y=y}
end

function love.draw()
	love.graphics.translate(translate.x, translate.y)
	love.graphics.scale(scale)
	love.graphics.draw(image)
	love.graphics.setColor(POINT_COLOR)
	for i,v in ipairs(points) do
		love.graphics.circle("fill",v.x,v.y,POINT_RADIUS)
	end
	for i,v in ipairs(triangles) do
		v:draw()
	end
	love.graphics.setColor(POINTER_COLOR[mode])
	if mode == "green" or mode == "red" then
		if #currentTriangle > 0 then
			local line = {}
			for i,v in ipairs(currentTriangle) do
				line[#line+1] = v.x
				line[#line+1] = v.y
			end
			line[#line+1] = latestPosition.x
			line[#line+1] = latestPosition.y
			love.graphics.line(line)
		end
	end
	love.graphics.circle("fill",latestPosition.x,latestPosition.y,POINT_RADIUS/scale)
	love.graphics.setColor(WHITE)


end

function love.mousepressed(x,y,button)
	if moving or moving2 then return end
	if button == 3 then
		moving = true
	end
	x = x - translate.x
	y = y - translate.y
	x = x / scale
	y = y / scale
	if button == 1 then
		if mode == "points" then
			if not findPoint(x,y,MIN_POINT_DISTANCE) then
				local p = point:new(x,y)
				points[#points+1] = p
			end
		elseif mode == "delete" then
			local p = findPoint(x,y,POINT_HIT_DISTANCE)
			if p then
				p:remove()
				return
			end
			for i,v in ipairs(triangles) do
				if v:contains(x,y) then
					v:remove()
				end
			end
		elseif mode == "green" or mode == "red" then
			for i,v in ipairs(points) do
				if dist(v,{x=x,y=y}) < POINT_HIT_DISTANCE and not containsPoint(currentTriangle,v)then
						currentTriangle[#currentTriangle+1] = v
					if #currentTriangle == 3 then
						local t = triangle:new(mode,currentTriangle)
						triangles[#triangles+1] = t
						currentTriangle = {}
					end
				end
			end
		end
	end
end

function love.wheelmoved(wx,wy)
	x, y = love.mouse.getPosition();
	x = x - translate.x
	y = y - translate.y
	x = x / scale
	y = y / scale
	local oldscale = scale
	scale = scale + wy * SCALING_FACTOR
	translate.x = translate.x + x * (oldscale - scale)
	translate.y = translate.y + y * (oldscale - scale)

end

function love.mousemoved(x,y,dx,dy)
	if moving or moving2 then
		translate.x = translate.x + dx
		translate.y = translate.y + dy
	end
end
function love.mousereleased(x,y,button)
	if button == 3 then
		moving = false
	end
end

function love.keypressed(key)
	if moving or moving2 then return end
	if key == "escape" then
		saveMesh()
		love.event.quit()
	elseif key == "p" or key == "b" or key == "1" then
		mode = "points"
	elseif key == "g" or key == "2" then
		mode = "green"
		currentTriangle = {}
	elseif key == "r" or key == "3" then
		mode = "red"
		currentTriangle = {}
	elseif key == "d" or key == "4" then
		mode = "delete"
	elseif key == "space" then
		moving2 = true
	end
end

function love.keyreleased(key)
	if key == "space" then
		moving2 = false
	end
end

function dist(o1,o2)
	local a = o1.x - o2.x
	local b = o1.y - o2.y
	return math.sqrt(a*a+b*b)
end

