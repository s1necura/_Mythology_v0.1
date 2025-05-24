// Gingerbeard @ January 13th, 2025
// A* Pathfinding Implementation for King Arthur's Gold

#include "PathingNodesCommon.as";
#include "RunnerCommon.as";

/*
 High-level pathing ensures efficient, large-scale navigation across the map.
 Low-level pathing provides precise, obstacle-aware movement.

 When applied in the system:
  - High-level pathing determines the general route.
  - Low-level pathing follows that route waypoint to waypoint.
*/

/*
  TODO:
  - Allow for high level node connections to incorporate blob obstructions (so bots dont try and path through doors etc)
 */

const u32 stuck_time = 30 * 3; // Time it takes to shut off a specific waypoint if the bot cannot pass fast enough

const f32 maximum_pathing_distance_high_level = tilesize * 70;
const f32 maximum_pathing_distance_low_level = tilesize * 15;

class PathHandler
{
	CMap@ map = getMap();

	Vec2f[] waypoints;           // High level path
	Vec2f[] path;                // Low level path
	dictionary cached_waypoints; // Stuck nodes for 'stuck' state processing
	Vec2f destination;           // Target destination
	u8 team;                     // Decides what doors we can pass through
	u8 flags;                    // Decides what paths to use
	u8 variance;                 // Max amount of random cost we give to each high level node
	f32 reach_low_level;         // What distance we can 'reach' low level path nodes
	f32 reach_high_level;        // What distance we can 'reach' high level waypoints
	
	PathHandler(const u8&in team, const u8&in flags = Path::GROUND)
	{
		this.team = team;
		this.flags = flags;
		
		reach_low_level = 10.0f;
		reach_high_level = 20.0f;
		variance = 50;
	}
	
	void Tick(Vec2f&in position)
	{
		// Handle 'stuck' operations
		const string[]@ cached_keys = cached_waypoints.getKeys();
		for (int i = 0; i < cached_keys.length; i++)
		{
			CachedWaypoint@ cached_waypoint;
			if (!cached_waypoints.get(cached_keys[i], @cached_waypoint)) continue;
			
			if ((cached_waypoint.position - position).Length() < reach_high_level)
			{
				cached_waypoints.delete(cached_keys[i]);
				continue;
			}
			
			if (cached_waypoint.stuck) continue;
			
			if (waypoints.length > 0 && waypoints[0] == cached_waypoint.position)
			{
				cached_waypoint.time++;
				
				if (cached_waypoint.time > stuck_time)
				{
					cached_waypoint.stuck = true;
					SetPath(position, waypoints[waypoints.length - 1]);
				}
			}
		}

		while (path.length > 0 && (path[0] - position).Length() < reach_low_level)
		{
			// Remove paths that we have reached
			path.removeAt(0);
		}

		while (waypoints.length > 0 && (waypoints[0] - position).Length() < reach_high_level)
		{
			ProgressPath(position);
		}
	}
	
	void ProgressPath(Vec2f&in position)
	{
		// Remove waypoints that we have reached
		string waypoint_key = waypoints[0].toString();
		if (cached_waypoints.exists(waypoint_key))
		{
			cached_waypoints.delete(waypoint_key);
		}

		waypoints.removeAt(0);
		path.clear();
		if (waypoints.length > 0)
		{
			SetLowLevelPath(position, waypoints[0]);
			CacheWaypoint(waypoints[0]);
		}
	}
	
	void CacheWaypoint(Vec2f&in waypoint)
	{
		// Cache the waypoint as a potential 'stuck' node
		const string waypoint_key = waypoint.toString();
		if (!cached_waypoints.exists(waypoint_key))
		{
			CachedWaypoint@ cached = CachedWaypoint(waypoint);
			cached_waypoints.set(waypoint_key, cached);
		}
	}
	
	void SetPath(Vec2f&in start, Vec2f&in target)
	{
		destination = target;
		SetHighLevelPath(start, target);
		if (waypoints.length > 0)
		{
			CacheWaypoint(waypoints[0]);
			SetLowLevelPath(start, waypoints[0]);
		}
	}
	
	void Repath(Vec2f&in start)
	{
		if (destination != Vec2f_zero)
		{
			SetPath(start, destination);
		}
	}
	
	void EndPath()
	{
		waypoints.clear();
		path.clear();
		cached_waypoints.deleteAll();
		destination = Vec2f_zero;
	}

	/// Heuristics
	
	f32 euclidean(Vec2f&in a, Vec2f&in b)
	{
		return (a - b).Length(); // Euclidean distance
	}
	
	f32 manhattan(Vec2f&in a, Vec2f&in b)
	{
		return Maths::Abs(a.x - b.x) + Maths::Abs(a.y - b.y); // Manhattan distance
	}
	
	/// High level

	void SetHighLevelPath(Vec2f&in start, Vec2f&in target)
	{
		waypoints.clear();

		HighLevelNode@[]@ nodeMap;
		if (!getRules().get("node_map", @nodeMap)) return;

		HighLevelNode@ startNode = getClosestNode(start, nodeMap, flags);
		HighLevelNode@ targetNode = getClosestNode(target, nodeMap, flags);
		if (startNode is null || targetNode is null) return;

		HighLevelNode@[] openList;
		dictionary closedList;

		startNode.gCost = 0.0f;
		startNode.hCost = euclidean(startNode.position, targetNode.position);
		@startNode.parent = null;

		openList.push_back(startNode);

		HighLevelNode@ closestToTarget = null;
		f32 closestDistance = 999999.0f;

		while (openList.length > 0)
		{
			// Find the node with the lowest fCost in the open list
			int currentIndex = 0;
			for (int i = 1; i < openList.length; i++)
			{
				HighLevelNode@ a = openList[i];
				HighLevelNode@ b = openList[currentIndex];
				if (a.fCost() < b.fCost() || (a.fCost() == b.fCost() && a.hCost < b.hCost))
				{
					currentIndex = i;
				}
			}

			HighLevelNode@ currentNode = openList[currentIndex];
			
			// Skip if the node is blacklisted
			CachedWaypoint@ cached_waypoint;
			if (cached_waypoints.get(currentNode.position.toString(), @cached_waypoint))
			{
				if (cached_waypoint.stuck)
				{
					openList.removeAt(currentIndex);
					continue;
				}
			}

			// Update the fallback node if this node is closer to the target
			const f32 distanceToTarget = euclidean(currentNode.position, targetNode.position);
			if (distanceToTarget < closestDistance)
			{
				closestDistance = distanceToTarget;
				@closestToTarget = currentNode;
			}

			// Check if the target node is reached
			if (currentNode is targetNode)
			{
				// Reconstruct the best path to the target
				ReconstructHighLevelPath(targetNode);
				return;
			}

			// Remove the current node from the open list and add it to the closed list
			openList.removeAt(currentIndex);
			closedList.set(currentNode.original_position.toString(), true);

			// Evaluate all neighbors of the current node
			for (uint i = 0; i < currentNode.connections.length; i++)
			{
				HighLevelNode@ neighbor = currentNode.connections[i];
				if (closedList.exists(neighbor.original_position.toString())) continue;
				
				if (!neighbor.hasFlag(flags)) continue;

				if ((neighbor.position - startNode.position).Length() > maximum_pathing_distance_high_level) continue;

				const f32 waterCost = isUnderwater(currentNode.position) ? 60 : 0;
				const f32 groundCost = isGrounded(neighbor.position) ? 0 : 40;
				const f32 randomCost = XORRandom(variance);
				const f32 tentativeGCost = currentNode.gCost + waterCost + groundCost + randomCost + euclidean(currentNode.position, neighbor.position);

				// Check if the neighbor is not in the open list or if a better path is found
				const bool isEvaluated = isInOpenList(neighbor, openList);
				if (tentativeGCost < neighbor.gCost || !isEvaluated)
				{
					// Update the neighbor's costs and set its parent
					neighbor.gCost = tentativeGCost;
					neighbor.hCost = euclidean(neighbor.position, targetNode.position);
					@neighbor.parent = currentNode;

					if (!isEvaluated)
					{
						openList.push_back(neighbor);
					}
				}
			}
		}

		// If the target node was not reachable, reconstruct the path to the closest node
		if (closestToTarget !is null)
		{
			ReconstructHighLevelPath(closestToTarget);
		}
	}
	
	void ReconstructHighLevelPath(HighLevelNode@ node)
	{
		while (node !is null)
		{
			waypoints.insertAt(0, node.position);
			@node = node.parent;
		}
	}

	bool isInOpenList(HighLevelNode@ node, HighLevelNode@[]&in openList)
	{
		for (int i = 0; i < openList.length; i++)
		{
			if (openList[i] is node) return true;
		}
		return false;
	}

	bool canPath(Vec2f&in start, Vec2f&in target)
	{
		HighLevelNode@[]@ nodeMap;
		if (!getRules().get("node_map", @nodeMap)) return false;

		HighLevelNode@ startNode = getClosestNode(start, nodeMap, flags);
		HighLevelNode@ targetNode = getClosestNode(target, nodeMap, flags);
		if (startNode is null || targetNode is null) return false;
		
		f32 progressThreshold = euclidean(startNode.position, targetNode.position);
		Vec2f closestPos = startNode.position;

		dictionary closedList;
		HighLevelNode@[] openList;
		openList.push_back(startNode);

		while (openList.length > 0)
		{
			int bestIndex = 0;
			f32 bestDistance = euclidean(openList[0].position, targetNode.position);
			
			for (uint i = 1; i < openList.length(); i++)
			{
				const f32 dist = euclidean(openList[i].position, targetNode.position);
				if (dist < bestDistance)
				{
					bestDistance = dist;
					bestIndex = i;
				}
			}

			HighLevelNode@ currentNode = openList[bestIndex];
			if (currentNode is targetNode) return true;

			openList.removeAt(bestIndex);
			closedList.set(currentNode.original_position.toString(), true);
			
			if (bestDistance < progressThreshold)
			{
				progressThreshold = bestDistance;
				closestPos = currentNode.position;
			}

			for (uint i = 0; i < currentNode.connections.length; i++)
			{
				HighLevelNode@ neighbor = currentNode.connections[i];
				if (closedList.exists(neighbor.original_position.toString())) continue;

				if (!neighbor.hasFlag(flags)) continue;

				if ((neighbor.position - closestPos).Length() > maximum_pathing_distance_high_level) return false;

				if (!isInOpenList(neighbor, openList))
				{
					openList.insertAt(0, neighbor);
				}
			}
			
			openList.set_length(Maths::Min(openList.length, 8)); // Optimization
		}

		return false;
	}


	/// Low level

	void SetLowLevelPath(Vec2f&in start, Vec2f&in target)
	{
		start = map.getAlignedWorldPos(start + Vec2f(halfsize, halfsize));
		target = map.getAlignedWorldPos(target + Vec2f(halfsize, halfsize));
		
		path.clear();

		LowLevelNode@[] openList;
		dictionary closedList;

		openList.push_back(LowLevelNode(start, 0, manhattan(start, target), null));

		while (openList.length > 0)
		{
			// Find the node with the lowest fCost in the open list
			int currentIndex = 0;
			for (int i = 1; i < openList.length; i++)
			{
				LowLevelNode@ a = openList[i];
				LowLevelNode@ b = openList[currentIndex];
				if (a.fCost() < b.fCost() || (a.fCost() == b.fCost() && a.hCost < b.hCost))
				{
					currentIndex = i;
				}
			}

			LowLevelNode@ currentNode = openList[currentIndex];

			// Check if the target is reached
			if ((currentNode.position - target).Length() < 15.0f)
			{
				// Reconstruct best path
				LowLevelNode@ current = currentNode;
				while (current !is null)
				{
					path.insertAt(0, current.position);
					@current = current.parent;
				}

				return;
			}

			openList.removeAt(currentIndex);
			closedList.set(currentNode.position.toString(), @currentNode);

			for (u8 i = 0; i < 4; i++)
			{
				Vec2f neighborPos = currentNode.position + cardinalDirections[i];
				if (closedList.exists(neighborPos.toString())) continue; // Skip if already evaluated

				if (!isWalkable(neighborPos, currentNode.position)) continue;
				
				if ((neighborPos - start).Length() > maximum_pathing_distance_low_level) continue;

				// Check if neighbor is in the open list
				LowLevelNode@ neighborNode = null;
				for (uint j = 0; j < openList.length; j++)
				{
					if (openList[j].position == neighborPos)
					{
						@neighborNode = openList[j];
						break;
					}
				}
				
				const f32 underwaterPenalty = isUnderwater(currentNode.position) ? 60 : 0;
				const f32 groundPenalty = isGrounded(neighborPos) ? 0 : 40;
				const f32 tentativeGCost = currentNode.gCost + groundPenalty + underwaterPenalty;

				if (neighborNode is null)
				{
					// Add new neighbor to the open list
					openList.push_back(LowLevelNode(neighborPos, tentativeGCost, manhattan(neighborPos, target), currentNode));
				}
				else if (tentativeGCost < neighborNode.gCost)
				{
					// Update existing node with better gCost
					neighborNode.gCost = tentativeGCost;
					@neighborNode.parent = currentNode;
				}
			}
		}
	}

	bool isWalkable(Vec2f&in tilePos, Vec2f&in previousPos)
	{
		for (u8 i = 0; i < 4; i++)
		{
			if (map.isTileSolid(tilePos + walkableDirections[i])) return false;
		}
		
		CBlob@[] blobs;
		Vec2f tile(2, 2);
		if (map.getBlobsInBox(tilePos - tile, tilePos + tile, @blobs))
		{
			for (int i = 0; i < blobs.length; i++)
			{
				CBlob@ b = blobs[i];
				CShape@ shape = b.getShape();
				if (!shape.isStatic() || !shape.getConsts().collidable) continue;

				if (b.hasTag("door")) // Doors can only be pathed through if its our team or neutral
				{
					const u8 door_team = b.getTeamNum();
					if (door_team != team && door_team != 255)
					{
						return false;
					}
					continue;
				}
				const string name = b.getName();
				if (name == "lantern" || name == "bridge") return true;

				if (b.isPlatform()) // Platforms can only be pathed through if we arent going against it
				{
					ShapePlatformDirection@ plat = shape.getPlatformDirection(0);
					Vec2f dir = plat.direction;
					if (!plat.ignore_rotations) dir.RotateBy(b.getAngleDegrees());
					if (Maths::Abs(dir.AngleWith(b.getPosition() - previousPos)) > plat.angleLimit)
					{
						return false;
					}
					continue;
				}
				
				return false; // Other static blobs like mechanisms
			}
		}

		return true;
	}

	bool isGrounded(Vec2f&in tilePos)
	{
		// Ensure there is ground beneath the 2x2 tile area
		if (map.isTileSolid(tilePos + Vec2f(-halfsize, tilesize + halfsize))) return true;
		if (map.isTileSolid(tilePos + Vec2f(halfsize, tilesize + halfsize)))  return true;

		if (map.isInWater(tilePos)) return true;

		CBlob@[] blobs;
		Vec2f tile(halfsize, halfsize);
		if (map.getBlobsInBox(tilePos - tile, tilePos + tile, @blobs))
		{
			for (int i = 0; i < blobs.length; i++)
			{
				CBlob@ b = blobs[i];
				if (b.getShape().getVars().isladder) return true; // Ladders count as grounded
			}
		}

		return false;
	}

	bool isUnderwater(Vec2f&in tilePos)
	{
		for (u8 i = 0; i < 4; i++)
		{
			if (!map.isInWater(tilePos + walkableDirections[i])) return false;
		}
		return true;
	}
}

class CachedWaypoint
{
	Vec2f position;
	u32 time;
	bool stuck;
	
	CachedWaypoint(Vec2f&in pos)
	{
		position = pos;
		time = 1;
		stuck = false;
	}
}


/// BLOB

void SetPath(CBlob@ this, Vec2f&in target)
{
	PathHandler@ handler;
	if (!this.get("path_handler", @handler))
	{
		@handler = PathHandler(this.getTeamNum());
		this.set("path_handler", @handler);
	}

	handler.SetPath(this.getPosition(), target);
}

void EndPath(CBlob@ this)
{
	PathHandler@ handler;
	if (this.get("path_handler", @handler))
	{
		handler.EndPath();
	}
	this.setKeyPressed(key_left, false);
	this.setKeyPressed(key_right, false);
	this.setKeyPressed(key_up, false);
	this.setKeyPressed(key_down, false);
}

void SetSuggestedFacing(CBlob@ this)
{
	PathHandler@ handler;
	if (!this.get("path_handler", @handler)) return;
	
	Vec2f position = this.getPosition();

	if (handler.waypoints.length > 0 && (position - handler.waypoints[0]).Length() > 32.0f)
	{
		Vec2f newAimPos = Vec2f_lerp(this.getAimPos(), handler.waypoints[0], 0.25f);
		this.setAimPos(newAimPos);
	}
	else if (handler.path.length > 0 && (position - handler.path[handler.path.length - 1]).Length() > 20.0f)
	{
		Vec2f newAimPos = Vec2f_lerp(this.getAimPos(), handler.path[handler.path.length - 1], 0.25f);
		this.setAimPos(newAimPos);
	}
}

void SetSuggestedKeys(CBlob@ this)
{
	PathHandler@ handler;
	if (!this.get("path_handler", @handler)) return;
	
	if (handler.path.length == 0)
	{
		if (handler.waypoints.length == 0)
		{
			EndPath(this);
			return;
		}
		else
		{
			handler.path.push_back(handler.waypoints[0]);
		}
	}

	CMap@ map = getMap();
	Vec2f position = this.getPosition();
	Vec2f distance = handler.path[0] - position;
	Vec2f direction = distance;
	direction.Normalize();

	this.setKeyPressed(key_up, direction.y < -0.35f);
	this.setKeyPressed(key_down, direction.y > 0.5f);
	
	if (WallJump(this, map, handler, direction, distance)) return;

	if (ClimbWall(this, map, handler, direction, distance)) return;
	
	if (JumpOverHole(this, map, handler, direction, distance)) return;

	this.setKeyPressed(key_left, direction.x < -0.5f);
	this.setKeyPressed(key_right, direction.x > 0.5f);
}

bool WallJump(CBlob@ this, CMap@ map, PathHandler@ handler, Vec2f&in direction, Vec2f&in distance)
{
	if (direction.y < -0.35f)
	{
		if (handler.path.length <= 1) return false;

		Vec2f path_direction = handler.path[0] - handler.path[1];
		path_direction.Normalize();

		if (path_direction.y <= 0 || path_direction.x != 0) return false;
	}
	
	if (this.isOnLadder() || this.isInWater()) return false;

	RunnerMoveVars@ moveVars;
	if (!this.get("moveVars", @moveVars)) return false;
	
	if (moveVars.walljumped_side <= 0) return false;

	const bool left = moveVars.walljumped_side == Walljump::LEFT || moveVars.walljumped_side == Walljump::JUMPED_LEFT;
	const bool right = moveVars.walljumped_side == Walljump::RIGHT || moveVars.walljumped_side == Walljump::JUMPED_RIGHT;
	const int sign = left ? 1 : -1;
	Vec2f end = handler.path[0] + Vec2f(tilesize * 6 * sign, 0);

	// Find the next wall to jump off of
	if (map.rayCastSolid(handler.path[0], end))
	{
		this.setKeyPressed(key_up, true);
		this.setKeyPressed(key_down, false);
		this.setKeyPressed(key_right, left);
		this.setKeyPressed(key_left, right);
		
		if (handler.path[0].y > this.getPosition().y)
		{
			handler.path.erase(0);
		}

		return true;
	}
	
	return false;
}

bool ClimbWall(CBlob@ this, CMap@ map, PathHandler@ handler, Vec2f&in direction, Vec2f&in distance)
{
	if (direction.y < -0.35f && Maths::Abs(distance.x) < 4.0f && !this.isOnLadder())
	{
		Vec2f position = this.getPosition();
		const f32 radius = this.getRadius();
		const bool right = map.isTileSolid(Vec2f(position.x + radius + tilesize, position.y - halfsize)) ||
		                   map.isTileSolid(Vec2f(position.x + radius + tilesize, position.y + halfsize));
		const bool left  = map.isTileSolid(Vec2f(position.x - radius - tilesize, position.y - halfsize)) ||
		                   map.isTileSolid(Vec2f(position.x - radius - tilesize, position.y + halfsize));
		if (right || left)
		{
			// Move towards the adjacent wall
			this.setKeyPressed(key_left, left);
			this.setKeyPressed(key_right, right);
			return true;
		}
	}
	return false;
}

bool JumpOverHole(CBlob@ this, CMap@ map, PathHandler@ handler, Vec2f&in direction, Vec2f&in distance)
{
	if (handler.path.length <= 1) return false;
	
	if (this.isOnLadder() || this.isInWater()) return false;

	Vec2f depth = Vec2f(0, tilesize * 4);
	if (handler.path.length > 2 && map.rayCastSolid(handler.path[1], handler.path[1] + depth)) return false;
	if (map.rayCastSolid(handler.path[0], handler.path[0] + depth)) return false;

	Vec2f path_direction = handler.path[0] - handler.path[1];
	path_direction.Normalize();
	if (path_direction.y != 0) return false;
	
	if (handler.waypoints.length <= 0) return false;

	Vec2f position = this.getPosition();
	Vec2f distance_from_waypoint = handler.waypoints[0] - handler.path[0];
	if (distance_from_waypoint.y > tilesize * 3) return false;
	
	this.setKeyPressed(key_up, true);
	this.setKeyPressed(key_down, false);
	this.setKeyPressed(key_left, path_direction.x > 0);
	this.setKeyPressed(key_right, path_direction.x < 0);
	
	// Adjust the last path point to the nearest ground for a clean landing
	const int index = handler.path.length - 1;
	handler.path[index] = getJumpLanding(handler.path[index], position, handler);
	
	// Clear paths that we progress while jumping
	if (path_direction.x > 0 && position.x < handler.path[0].x ||
	    path_direction.x < 0 && position.x > handler.path[0].x)
	{
		handler.path.erase(0);

		if (handler.path.length == 1)
		{
			handler.ProgressPath(position);
		}
	}

	return true;
}

Vec2f getJumpLanding(Vec2f&in tilePos, Vec2f&in position, PathHandler@ handler)
{
	if (handler.isGrounded(tilePos) && handler.isWalkable(tilePos, position)) return tilePos;

	Vec2f best_position = tilePos;
	f32 closest_dist = 99999.0f;

	const int searchRadius = 3;
	for (int y = -searchRadius; y <= searchRadius; y++)
	{
		for (int x = -searchRadius; x <= searchRadius; x++)
		{
			Vec2f nodePos = tilePos + Vec2f(x * tilesize, y * tilesize);
			if (!handler.isGrounded(nodePos) || !handler.isWalkable(nodePos, position)) continue;
			
			const f32 dist = (nodePos - tilePos).Length();
			if (dist < closest_dist)
			{
				best_position = nodePos;
				closest_dist = dist;
			}
		}
	}
	return best_position;
}
