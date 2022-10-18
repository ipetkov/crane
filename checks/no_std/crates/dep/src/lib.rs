#![cfg_attr(target_os = "none", no_std)]

use serde::{Deserialize, Serialize};

#[derive(Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct FortyTwo;

impl FortyTwo {
    pub fn new() -> Self {
        Self
    }
}

impl From<FortyTwo> for u8 {
    fn from(_: FortyTwo) -> Self {
        42
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn forty_two() {
        assert_eq!(super::FortyTwo::new(), super::FortyTwo);
        let forty_two: u8 = super::FortyTwo::new().into();
        assert_eq!(forty_two, 42);
    }
}
