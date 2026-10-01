//! `app` entry point.
//!
//! Rename the crate, the binary, and the package before doing anything else.
//! See the README for the exact steps.

/// Returns a greeting, so there is something to test from the start.
fn greeting() -> String {
    "Hello, world!".to_owned()
}

fn main() {
    println!("{}", greeting());
}

#[cfg(test)]
mod tests {
    use super::greeting;

    /// Smoke test, so the template has a passing suite out of the box.
    #[test]
    fn greeting_is_not_empty() {
        assert!(!greeting().is_empty());
    }
}
