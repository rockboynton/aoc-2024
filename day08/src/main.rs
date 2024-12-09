use itertools::Itertools;
use std::collections::{HashMap, HashSet};

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
struct Point {
    x: isize,
    y: isize,
}

impl Point {
    fn symmetric_point(&self, other: &Point) -> Point {
        Point {
            x: self.x + (self.x - other.x),
            y: self.y + (self.y - other.y),
        }
    }

    // Finds the antinode points given two antenna locations with integer coordinates
    fn antinodes(a: Point, b: Point) -> (Point, Point) {
        (a.symmetric_point(&b), b.symmetric_point(&a))
    }

    fn in_bounds(&self, rows: isize, cols: isize) -> bool {
        (0..rows).contains(&self.y) && (0..cols).contains(&self.x)
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
struct Frequency(char);

fn main() {
    println!("{}", solve(include_str!("../input.txt")));
}

fn solve(input: &str) -> u64 {
    let mut antenna_map: HashMap<Frequency, Vec<Point>> = HashMap::new();
    let mut rows = 0;
    let mut cols = 0;
    for (y, row) in input.lines().enumerate() {
        cols = 0;
        for (x, c) in row.chars().enumerate() {
            if c != '.' {
                let x = x as isize;
                let y = y as isize;
                let freq = Frequency(c);
                antenna_map.entry(freq).or_default().push(Point { x, y });
            }
            cols += 1;
        }
        rows += 1;
    }

    let mut antinodes = HashSet::new();

    for points in antenna_map.values() {
        let pairs: Vec<Vec<&Point>> = points.iter().permutations(2).collect();

        for points in pairs.iter() {
            let (a1, a2) = Point::antinodes(*points[0], *points[1]);
            if a1.in_bounds(rows, cols) {
                antinodes.insert(a1);
            }
            if a2.in_bounds(rows, cols) {
                antinodes.insert(a2);
            }
        }
    }

    antinodes.len() as u64
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_solve_part1() {
        let input = include_str!("../example.txt");

        let part1 = solve(input);
        assert_eq!(part1, 14);
    }

    #[test]
    fn antinodes() {
        let a = Point { x: 5, y: 5 };
        let b = Point { x: 4, y: 3 };

        let (a1, a2) = Point::antinodes(a, b);
        assert_eq!(a1, Point { x: 6, y: 7 });
        assert_eq!(a2, Point { x: 3, y: 1 });
    }
}