class_name GridGraph
#图类，寻路由它来负责（实质上是对AStar的包装）

#邻接点的选择范围，这里是八方向
#把对角线去掉，就变成了四方向（垂直和水平）移动
const ADJ = [
	Vector2(+0, +1), Vector2(+0, -1), Vector2(+1, +0), Vector2(-1, +0),
	Vector2(-1, -1), Vector2(-1, +1), Vector2(+1, -1), Vector2(+1, +1),
]
#Godot提供的寻路工具
var _astar := AStar2D.new()
#缓存边，邻接表
var _edges = {}
#ID自动增长
var _next_id = 0

func _add_edge(p1:int, p2:int):
	if not _edges.has(p1):
		_edges[p1] = []
	_edges[p1].append(p2)
func _remove_edge(p1:int, p2:int):
	if _edges.has(p1):
		var idx = _edges[p1].find(p2)
		if idx >= 0: _edges[p1].remove(idx)
	if _edges.has(p2):
		var idx = _edges[p2].find(p1)
		if idx >= 0: _edges[p2].remove(idx)

#根据坐标获取对应的顶点ID，如果不存在，返回负数
func _to_vid(v:Vector2) -> int:
	var pid = _astar.get_closest_point(v)
	if pid < 0: return -1
	if v != _astar.get_point_position(pid):
		return -2
	return pid

#添加一个路径点，并自动连接邻接点
func add_vertex(v:Vector2) -> int:
	#这个点已经存在了
	if (_to_vid(v) >= 0):
		if D != null: D.w("GridGraph: " + String(v) + " already exists!")
		return FAILED
	#添加点
	var vid = _next_id
	_astar.add_point(_next_id, v)
	_next_id += 1
	#添加连线
	for adj in ADJ:
		var v2 = adj + v
		var v2id = _to_vid(v2)
		if v2id >= 0:
			_astar.connect_points(vid, v2id)
			_add_edge(vid, v2id)
	return OK

#移除一个路径点，并自动断开与邻接点的连接
func remove_vertex(v:Vector2) -> int:
	#这个点存在
	var vid = _to_vid(v)
	if (vid < 0):
		if D != null: D.w("GridGraph: " + "Nonexistent point " + String(v) + "!")
		return FAILED
	#移除缓存边，暂时不考虑性能
	for v2id in _astar.get_point_connections(_to_vid(v)):
		_remove_edge(vid, v2id)
	_edges.erase(vid)
	#移除点
	_astar.remove_point(vid)
	return OK

#计算路径
var _path #保存最近一次计算的路径，会画出来
func calculate_path(from:Vector2, to:Vector2) -> PoolVector2Array:
	var vid = _to_vid(from);
	if vid < 0:
		if D != null: D.w("GridGraph: " + "Nonexistent point " + String(from) + "!")
		return PoolVector2Array()
	var v2id = _to_vid(to);
	if v2id < 0:
		if D != null: D.w("GridGraph: " + "Nonexistent point " + String(to) + "!")
		return PoolVector2Array()
	_path = _astar.get_point_path(vid, v2id)
	return _path

#清空图
func clear_graph():
	_edges = {}
	_astar.clear()

#绘制图，应该在CanvasItem节点的_draw函数中调用

func draw_grid_graph(ci:CanvasItem, cell_size := 32):
	#画点
	for vid in _astar.get_points():
		var v:Vector2 = _astar.get_point_position(vid)
		ci.draw_rect(Rect2((v+Vector2(0.4, 0.4))*cell_size, Vector2(0.2, 0.2)*cell_size), Color.green, true)
	#画边
	var points = PoolVector2Array()
	for vid in _edges:
		var v = _astar.get_point_position(vid)
		for v2id in _edges[vid]:
			var v2 = _astar.get_point_position(v2id)
			points.append((v + Vector2(0.5, 0.5)) * cell_size)
			points.append((v2 + Vector2(0.5, 0.5)) * cell_size)
	ci.draw_multiline(points, Color.green)
	
	#画最近一次计算的路径
	if _path == null: return
	for i in range(_path.size()-1):
		ci.draw_line((_path[i] + Vector2(0.5, 0.5)) * cell_size, (_path[i+1] + Vector2(0.5, 0.5)) * cell_size, Color.red, 2.0, true)
