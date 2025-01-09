package main
import "core:fmt"
import rl "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450

SQUARE_SIZE :: 20

GRID_HORIZONTAL_SIZE :: 12
GRID_VERTICAL_SIZE :: 20

GridSquare :: enum u8 {
	Empty,
	Moving,
	Full,
	Block,
	Fading,
}

Directions :: enum u8 {
	Down,
	Left,
	Right,
}

Piece :: struct {
	shape:    [4][4]GridSquare,
	position: [2]int,
	width:    int,
	height:   int,
	isActive: bool,
}

grid: [GRID_HORIZONTAL_SIZE][GRID_VERTICAL_SIZE]GridSquare
gameOver := false
pause := false

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Tetris")
	defer rl.CloseWindow()

	rl.SetTargetFPS(12)

	piece: Piece
	piece.isActive = false

	nextPiece: Piece
	nextPiece.isActive = false

	initializeGame()

	for !rl.WindowShouldClose() {
		updateGame(&piece)
		drawGame()
	}

	rl.CloseWindow()

}

initializeGame :: proc() {
	for i in 0 ..< GRID_HORIZONTAL_SIZE {
		for j in 0 ..< GRID_VERTICAL_SIZE {
			switch {
			case j == GRID_VERTICAL_SIZE - 1, i == GRID_HORIZONTAL_SIZE - 1, i == 0:
				grid[i][j] = .Block
			case:
				grid[i][j] = .Empty
			}
		}
	}
}

drawGame :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.RAYWHITE)

	if gameOver {
		rl.DrawText("Game over", SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, 32, rl.GRAY)
		return
	}

	if pause {
		rl.DrawText("Game Paused ", SCREEN_WIDTH / 2, SCREEN_WIDTH / 2, 40, rl.GRAY)
	}

	offset := [2]i32 {
		SCREEN_WIDTH / 2 - (GRID_HORIZONTAL_SIZE * SQUARE_SIZE / 2),
		SCREEN_HEIGHT / 2 - (GRID_VERTICAL_SIZE * SQUARE_SIZE / 2),
	}
	initialOffset := offset.x

	for j in 0 ..< GRID_VERTICAL_SIZE {
		for i in 0 ..< GRID_HORIZONTAL_SIZE {
			switch grid[i][j] {
			case .Empty:
				rl.DrawLine(offset.x, offset.y, offset.x + SQUARE_SIZE, offset.y, rl.LIGHTGRAY)
				rl.DrawLine(offset.x, offset.y, offset.x, offset.y + SQUARE_SIZE, rl.LIGHTGRAY)
				rl.DrawLine(
					offset.x + SQUARE_SIZE,
					offset.y,
					offset.x + SQUARE_SIZE,
					offset.y + SQUARE_SIZE,
					rl.LIGHTGRAY,
				)
				rl.DrawLine(
					offset.x,
					offset.y + SQUARE_SIZE,
					offset.x + SQUARE_SIZE,
					offset.y + SQUARE_SIZE,
					rl.LIGHTGRAY,
				)
			case .Block:
				rl.DrawRectangle(offset.x, offset.y, SQUARE_SIZE, SQUARE_SIZE, rl.LIGHTGRAY)
			case .Full:
				rl.DrawRectangle(offset.x, offset.y, SQUARE_SIZE, SQUARE_SIZE, rl.BLUE)
			case .Moving:
				rl.DrawRectangle(offset.x, offset.y, SQUARE_SIZE, SQUARE_SIZE, rl.RED)
			case .Fading:
				rl.DrawRectangle(offset.x, offset.y, SQUARE_SIZE, SQUARE_SIZE, rl.GREEN)
			}
			offset.x += SQUARE_SIZE
		}
		offset.x = initialOffset
		offset.y += SQUARE_SIZE
	}
}

updateGame :: proc(piece: ^Piece) {
	if gameOver {
		if rl.IsKeyPressed(.ENTER) {
			initializeGame()
			gameOver = false
		}
	}

	if rl.IsKeyPressed(.P) {
		pause = !pause
	}

	if pause {
		return
	}

	if !piece.isActive {
		createPiece(piece)
	} else {
		if rl.IsKeyPressed(.A) || rl.IsKeyPressed(.LEFT) {
			moveHorizontally(Directions.Left, piece)
		}
		if rl.IsKeyPressed(.D) || rl.IsKeyPressed(.RIGHT) {
			moveHorizontally(Directions.Right, piece)
		}
		if rl.IsKeyPressed(.S) || rl.IsKeyPressed(.DOWN) {
			moveVertically(piece)
		}
		if rl.IsKeyPressed(.SPACE) {
			piece.isActive = false
			clearPiece(piece)
		}

		moveVertically(piece)

	}
}

createPiece :: proc(piece: ^Piece) {
	random := rl.GetRandomValue(0, 6)

	setShape(piece, .Empty)

	switch random {
	case 0:
		// Square
		piece.shape[0][0] = .Moving
		piece.shape[1][0] = .Moving
		piece.shape[0][1] = .Moving
		piece.shape[1][1] = .Moving
		piece.width = 2
		piece.height = 2
	case 1:
		// I
		piece.shape[0][0] = .Moving
		piece.shape[1][0] = .Moving
		piece.shape[2][0] = .Moving
		piece.shape[3][0] = .Moving
		piece.width = 4
		piece.height = 1
	case 2:
		// L
		piece.shape[0][0] = .Moving
		piece.shape[0][1] = .Moving
		piece.shape[0][2] = .Moving
		piece.shape[1][2] = .Moving
		piece.width = 2
		piece.height = 3
	case 3:
		// s
		piece.shape[0][0] = .Moving
		piece.shape[1][0] = .Moving
		piece.shape[1][1] = .Moving
		piece.shape[2][1] = .Moving
		piece.width = 3
		piece.height = 2
	case 4:
		// L inverted
		piece.shape[0][2] = .Moving
		piece.shape[1][0] = .Moving
		piece.shape[1][1] = .Moving
		piece.shape[1][2] = .Moving
		piece.width = 2
		piece.height = 3
	case 5:
		// z
		piece.shape[0][0] = .Moving
		piece.shape[1][0] = .Moving
		piece.shape[1][1] = .Moving
		piece.shape[2][1] = .Moving
		piece.width = 3
		piece.height = 2
	case 6:
		// T
		piece.shape[0][0] = .Moving
		piece.shape[0][1] = .Moving
		piece.shape[0][2] = .Moving
		piece.shape[1][1] = .Moving
		piece.width = 2
		piece.height = 3
	}

	piece.isActive = true
	piece.position.x = (GRID_HORIZONTAL_SIZE - piece.width) / 2
	piece.position.y = 0

	putPieceInGrid(piece, .Moving)
}

putPieceInGrid :: proc(piece: ^Piece, state: GridSquare) {
	for i in piece.position.x ..< piece.position.x + piece.width {
		for j in piece.position.y ..< piece.position.y + piece.height {
			grid[i][j] = piece.shape[i - piece.position.x][j - piece.position.y]
		}
	}
}

clearPiece :: proc(piece: ^Piece) {
	for i in piece.position.x ..< piece.position.x + 4 {
		for j in piece.position.y ..< piece.position.y + 4 {
			if piece.shape[i - piece.position.x][j - piece.position.y] == .Moving {
				grid[i][j] = .Empty
			}
		}
	}
}

setShape :: proc(piece: ^Piece, state: GridSquare) {
	for i in 0 ..< 4 {
		for j in 0 ..< 4 {
			if piece.shape[i][j] != .Empty {
				piece.shape[i][j] = state
			}
		}
	}
}

moveHorizontally :: proc(direction: Directions, piece: ^Piece) {
	if direction == Directions.Left {
		pieceCanMove := !didCollide(piece, Directions.Left)
		if (pieceCanMove) {
			clearPiece(piece)
			piece.position.x -= 1
			putPieceInGrid(piece, .Moving)
		}


	} else if (direction == Directions.Right) {
		pieceCanMove := !didCollide(piece, Directions.Right)
		if (pieceCanMove) {
			clearPiece(piece)
			piece.position.x += 1
			putPieceInGrid(piece, .Moving)
		}
	}
}

moveVertically :: proc(piece: ^Piece) {
	pieceCanMove := !didCollide(piece, Directions.Down)
	if (pieceCanMove) {
		clearPiece(piece)
		piece.position.y += 1
		putPieceInGrid(piece, .Moving)
	} else {
		if (piece.position.y == 0) {
			gameOver = true
		}

		piece.isActive = false
		setShape(piece, .Full)
		putPieceInGrid(piece, .Full)
	}
}

didCollide :: proc(piece: ^Piece, direction: Directions) -> bool {
	switch direction {
	case Directions.Right:
		for j in 0 ..< piece.height {
			if piece.shape[piece.width - 1][j] != .Empty {
				if (grid[piece.position.x + piece.width][piece.position.y + j] == .Block) {
					return true
				} else if (grid[piece.position.x + piece.width][piece.position.y + j] == .Full) {
					return true
				}
			}
		};case Directions.Left:
		for j in 0 ..< piece.height {
			if piece.shape[0][j] != .Empty {
				if (grid[piece.position.x - 1][piece.position.y + j] == .Block) {
					return true
				} else if (grid[piece.position.x - 1][piece.position.y + j] == .Full) {
					return true
				}
			}
		}
	case Directions.Down:
		for i in 0 ..< 4 {
			if piece.shape[i][piece.height - 1] != .Empty {
				if (grid[piece.position.x + i][piece.position.y + piece.height] == .Block) {
					return true
				} else if (grid[piece.position.x + i][piece.position.y + piece.height] == .Full) {
					return true
				}
			}
		}
	}
	return false
}
