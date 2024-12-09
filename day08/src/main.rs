use itertools::Itertools;
use std::collections::{HashMap, HashSet};

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
struct Point {
    x: isize,
    y: isize,
}

impl Point {
    fn antinode(&self, other: &Point) -> Point {
        Point {
            x: self.x + (self.x - other.x),
            y: self.y + (self.y - other.y),
        }
    }

    fn in_bounds(&self, rows: isize, cols: isize) -> bool {
        (0..rows).contains(&self.y) && (0..cols).contains(&self.x)
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
struct Frequency(char);

fn main() {
    println!("{}", solve(include_str!("../input.txt"), false));
    println!("{}", solve(include_str!("../input.txt"), true));
}

fn solve(input: &str, with_harmonics: bool) -> u64 {
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
            if with_harmonics {
                let mut p0 = *points[0];
                let mut p1 = *points[1];
                while p1.in_bounds(rows, cols) {
                    antinodes.insert(p1);
                    let tmp = p0;
                    p0 = p0.antinode(&p1);
                    p1 = tmp;
                }
            } else {
                let antinode = points[0].antinode(points[1]);
                if antinode.in_bounds(rows, cols) {
                    antinodes.insert(antinode);
                }
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

        let part1 = solve(input, false);
        assert_eq!(part1, 14);
    }

    #[test]
    fn test_solve_part2() {
        let input = include_str!("../example.txt");

        let part1 = solve(input, true);
        assert_eq!(part1, 34);
    }

    #[test]
    fn test_solve_part2_extra() {
        let input = "T.........
...T......
.T........
..........
..........
..........
..........
..........
..........
..........
";

        let res = solve(input, true);
        assert_eq!(res, 9);
    }

    #[test]
    fn antinodes() {
        let a = Point { x: 5, y: 5 };
        let b = Point { x: 4, y: 3 };

        let a1 = a.antinode(&b);
        let a2 = b.antinode(&a);
        assert_eq!(a1, Point { x: 6, y: 7 });
        assert_eq!(a2, Point { x: 3, y: 1 });
    }
}
