use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
struct TestStruct {
    name: String,
    version: String,
}

fn main() {
    let test_data = TestStruct {
        name: "strip-version-test".to_string(),
        version: "1.2.3".to_string(),
    };

    println!("Hello from version stripping test!");
    println!("Package: {}", test_data.name);
    println!("Version: {}", test_data.version);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_serialization() {
        let test_data = TestStruct {
            name: "test".to_string(),
            version: "0.0.0".to_string(),
        };

        let serialized = serde_json::to_string(&test_data).unwrap();
        let deserialized: TestStruct = serde_json::from_str(&serialized).unwrap();

        assert_eq!(test_data.name, deserialized.name);
        assert_eq!(test_data.version, deserialized.version);
    }
}
