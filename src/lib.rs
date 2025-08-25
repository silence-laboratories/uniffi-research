use std::collections::HashMap;
use std::sync::{Arc, Mutex, OnceLock};

// Trait for simple callback functions that can be implemented by Kotlin/Swift/Dart
#[uniffi::export(callback_interface)]
pub trait EventCallback: Send + Sync {
    fn on_event(&self, event_type: String, message: String);
    fn on_data_received(&self, data: Vec<u8>) -> String;
    fn add_two_numbers(&self, a: i32, b: i32) -> i32;
}

// Trait for a data processor that can be implemented in Dart and used in Rust
#[uniffi::export(callback_interface)]
pub trait DataProcessor: Send + Sync {
    fn process_item(&self, item: String) -> ProcessResult;
    fn validate_input(&self, input: String) -> bool;
    fn transform_data(&self, data: Vec<String>) -> Vec<String>;
    fn get_processor_name(&self) -> String;
}

// Trait for a user profile manager
#[uniffi::export(callback_interface)]
pub trait UserProfileManager: Send + Sync {
    fn get_user_info(&self, user_id: u32) -> UserInfo;
    fn update_preferences(&self, user_id: u32, preferences: UserPreferences) -> bool;
    fn calculate_score(&self, user_id: u32, metrics: Vec<f64>) -> f64;
    fn notify_user(&self, user_id: u32, message: String);
}

// Trait for storage client that can be implemented in Dart
#[uniffi::export(callback_interface)]
pub trait StorageClient: Send + Sync {
    fn read(&self, key: String) -> StorageResult;
    fn write(&self, key: String, value: String) -> StorageResult;
}

// Trait for WebSocket client that can be implemented in Dart
#[uniffi::export(callback_interface)]
pub trait WebSocketClient: Send + Sync {
    fn send(&self, message: String) -> WebSocketResult;
    fn read(&self) -> WebSocketResult;
}

// Data structures that will be used with the traits
#[derive(uniffi::Record)]
pub struct ProcessResult {
    pub success: bool,
    pub result: String,
    pub metadata: String,
    pub timestamp: u64,
}

#[derive(uniffi::Record)]
pub struct UserInfo {
    pub id: u32,
    pub name: String,
    pub email: String,
    pub level: u32,
}

#[derive(uniffi::Record)]
pub struct UserPreferences {
    pub theme: String,
    pub notifications_enabled: bool,
    pub language: String,
    pub auto_save: bool,
}

#[derive(uniffi::Record)]
pub struct StorageResult {
    pub success: bool,
    pub data: String,
    pub error_message: String,
    pub timestamp: u64,
}

#[derive(uniffi::Record)]
pub struct WebSocketResult {
    pub success: bool,
    pub message: String,
    pub error_message: String,
    pub connection_status: String,
    pub timestamp: u64,
}

// Global registries for different types of callbacks
static CALLBACK_REGISTRY: OnceLock<Mutex<HashMap<u32, Arc<dyn EventCallback>>>> = OnceLock::new();
static DATA_PROCESSOR_REGISTRY: OnceLock<Mutex<HashMap<u32, Arc<dyn DataProcessor>>>> =
    OnceLock::new();
static USER_MANAGER_REGISTRY: OnceLock<Mutex<HashMap<u32, Arc<dyn UserProfileManager>>>> =
    OnceLock::new();
static STORAGE_CLIENT_REGISTRY: OnceLock<Mutex<HashMap<u32, Arc<dyn StorageClient>>>> =
    OnceLock::new();
static WEBSOCKET_CLIENT_REGISTRY: OnceLock<Mutex<HashMap<u32, Arc<dyn WebSocketClient>>>> =
    OnceLock::new();
static NEXT_ID: OnceLock<Mutex<u32>> = OnceLock::new();

fn get_registry() -> &'static Mutex<HashMap<u32, Arc<dyn EventCallback>>> {
    CALLBACK_REGISTRY.get_or_init(|| Mutex::new(HashMap::new()))
}

fn get_data_processor_registry() -> &'static Mutex<HashMap<u32, Arc<dyn DataProcessor>>> {
    DATA_PROCESSOR_REGISTRY.get_or_init(|| Mutex::new(HashMap::new()))
}

fn get_user_manager_registry() -> &'static Mutex<HashMap<u32, Arc<dyn UserProfileManager>>> {
    USER_MANAGER_REGISTRY.get_or_init(|| Mutex::new(HashMap::new()))
}

fn get_storage_client_registry() -> &'static Mutex<HashMap<u32, Arc<dyn StorageClient>>> {
    STORAGE_CLIENT_REGISTRY.get_or_init(|| Mutex::new(HashMap::new()))
}

fn get_websocket_client_registry() -> &'static Mutex<HashMap<u32, Arc<dyn WebSocketClient>>> {
    WEBSOCKET_CLIENT_REGISTRY.get_or_init(|| Mutex::new(HashMap::new()))
}

fn get_next_id() -> &'static Mutex<u32> {
    NEXT_ID.get_or_init(|| Mutex::new(1))
}

// Main service that accepts callbacks and provides functionality
#[derive(uniffi::Object)]
pub struct CallbackService {
    callback_id: Mutex<Option<u32>>,
}

#[uniffi::export]
impl CallbackService {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            callback_id: Mutex::new(None),
        })
    }

    pub fn get_status(&self) -> String {
        match *self.callback_id.lock().unwrap() {
            Some(_) => "Callback registered".to_string(),
            None => "No callback registered".to_string(),
        }
    }

    pub fn trigger_event(&self, event_type: String, message: String) {
        if let Some(id) = *self.callback_id.lock().unwrap() {
            if let Some(callback) = get_registry().lock().unwrap().get(&id) {
                callback.on_event(event_type, message);
            }
        }
    }

    pub fn process_data(&self, data: Vec<u8>) -> Option<String> {
        if let Some(id) = *self.callback_id.lock().unwrap() {
            if let Some(callback) = get_registry().lock().unwrap().get(&id) {
                Some(callback.on_data_received(data))
            } else {
                None
            }
        } else {
            None
        }
    }

    pub fn simulate_background_work(&self, duration_seconds: u32) {
        std::thread::sleep(std::time::Duration::from_secs(duration_seconds as u64));

        if let Some(id) = *self.callback_id.lock().unwrap() {
            if let Some(callback) = get_registry().lock().unwrap().get(&id) {
                callback.on_event(
                    "work_completed".to_string(),
                    format!(
                        "Background work completed after {} seconds",
                        duration_seconds
                    ),
                );
            }
        }
    }

    pub fn call_add_two_numbers(&self, a: i32, b: i32) -> Option<i32> {
        if let Some(id) = *self.callback_id.lock().unwrap() {
            if let Some(callback) = get_registry().lock().unwrap().get(&id) {
                Some(callback.add_two_numbers(a, b))
            } else {
                None
            }
        } else {
            None
        }
    }
}

// Service for working with DataProcessor objects
#[derive(uniffi::Object)]
pub struct DataProcessingService {
    processor_id: Mutex<Option<u32>>,
}

#[uniffi::export]
impl DataProcessingService {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            processor_id: Mutex::new(None),
        })
    }

    pub fn set_processor(&self, processor_id: u32) {
        *self.processor_id.lock().unwrap() = Some(processor_id);
    }

    pub fn process_single_item(&self, item: String) -> Option<ProcessResult> {
        if let Some(id) = *self.processor_id.lock().unwrap() {
            if let Some(processor) = get_data_processor_registry().lock().unwrap().get(&id) {
                Some(processor.process_item(item))
            } else {
                None
            }
        } else {
            None
        }
    }

    pub fn validate_and_process(&self, input: String) -> Option<ProcessResult> {
        if let Some(id) = *self.processor_id.lock().unwrap() {
            if let Some(processor) = get_data_processor_registry().lock().unwrap().get(&id) {
                if processor.validate_input(input.clone()) {
                    Some(processor.process_item(input))
                } else {
                    Some(ProcessResult {
                        success: false,
                        result: "Invalid input".to_string(),
                        metadata: "Validation failed".to_string(),
                        timestamp: std::time::SystemTime::now()
                            .duration_since(std::time::UNIX_EPOCH)
                            .unwrap()
                            .as_secs(),
                    })
                }
            } else {
                None
            }
        } else {
            None
        }
    }

    pub fn batch_transform(&self, data: Vec<String>) -> Option<Vec<String>> {
        if let Some(id) = *self.processor_id.lock().unwrap() {
            if let Some(processor) = get_data_processor_registry().lock().unwrap().get(&id) {
                Some(processor.transform_data(data))
            } else {
                None
            }
        } else {
            None
        }
    }

    pub fn get_processor_info(&self) -> Option<String> {
        if let Some(id) = *self.processor_id.lock().unwrap() {
            if let Some(processor) = get_data_processor_registry().lock().unwrap().get(&id) {
                Some(processor.get_processor_name())
            } else {
                None
            }
        } else {
            None
        }
    }
}

// Service for working with UserProfileManager objects
#[derive(uniffi::Object)]
pub struct UserService {
    manager_id: Mutex<Option<u32>>,
}

#[uniffi::export]
impl UserService {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            manager_id: Mutex::new(None),
        })
    }

    pub fn set_manager(&self, manager_id: u32) {
        *self.manager_id.lock().unwrap() = Some(manager_id);
    }

    pub fn get_user(&self, user_id: u32) -> Option<UserInfo> {
        if let Some(id) = *self.manager_id.lock().unwrap() {
            if let Some(manager) = get_user_manager_registry().lock().unwrap().get(&id) {
                Some(manager.get_user_info(user_id))
            } else {
                None
            }
        } else {
            None
        }
    }

    pub fn update_user_preferences(
        &self,
        user_id: u32,
        preferences: UserPreferences,
    ) -> Option<bool> {
        if let Some(id) = *self.manager_id.lock().unwrap() {
            if let Some(manager) = get_user_manager_registry().lock().unwrap().get(&id) {
                Some(manager.update_preferences(user_id, preferences))
            } else {
                None
            }
        } else {
            None
        }
    }

    pub fn calculate_user_score(&self, user_id: u32, metrics: Vec<f64>) -> Option<f64> {
        if let Some(id) = *self.manager_id.lock().unwrap() {
            if let Some(manager) = get_user_manager_registry().lock().unwrap().get(&id) {
                Some(manager.calculate_score(user_id, metrics))
            } else {
                None
            }
        } else {
            None
        }
    }

    pub fn send_notification(&self, user_id: u32, message: String) {
        if let Some(id) = *self.manager_id.lock().unwrap() {
            if let Some(manager) = get_user_manager_registry().lock().unwrap().get(&id) {
                manager.notify_user(user_id, message);
            }
        }
    }
}

// Service for working with StorageClient objects
#[derive(uniffi::Object)]
pub struct StorageService {
    client_id: Mutex<Option<u32>>,
}

#[uniffi::export]
impl StorageService {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            client_id: Mutex::new(None),
        })
    }

    pub fn set_client(&self, client_id: u32) {
        *self.client_id.lock().unwrap() = Some(client_id);
    }

    pub fn read_data(&self, key: String) -> Option<StorageResult> {
        if let Some(id) = *self.client_id.lock().unwrap() {
            if let Some(client) = get_storage_client_registry().lock().unwrap().get(&id) {
                Some(client.read(key))
            } else {
                None
            }
        } else {
            None
        }
    }

    pub fn write_data(&self, key: String, value: String) -> Option<StorageResult> {
        if let Some(id) = *self.client_id.lock().unwrap() {
            if let Some(client) = get_storage_client_registry().lock().unwrap().get(&id) {
                Some(client.write(key, value))
            } else {
                None
            }
        } else {
            None
        }
    }

    /// Read data from storage and then write it to another key (demonstrating combined operations)
    pub fn copy_data(&self, source_key: String, target_key: String) -> Option<StorageResult> {
        if let Some(id) = *self.client_id.lock().unwrap() {
            if let Some(client) = get_storage_client_registry().lock().unwrap().get(&id) {
                // First read from source
                let read_result = client.read(source_key);
                if read_result.success {
                    // Then write to target
                    Some(client.write(target_key, read_result.data))
                } else {
                    Some(read_result)
                }
            } else {
                None
            }
        } else {
            None
        }
    }

    /// Read multiple keys and write them as a batch to a single key
    pub fn backup_multiple_keys(
        &self,
        keys: Vec<String>,
        backup_key: String,
    ) -> Option<StorageResult> {
        if let Some(id) = *self.client_id.lock().unwrap() {
            if let Some(client) = get_storage_client_registry().lock().unwrap().get(&id) {
                let mut backup_data = Vec::new();

                // Read all keys
                for key in keys {
                    let result = client.read(key.clone());
                    if result.success {
                        backup_data.push(format!("{}:{}", key, result.data));
                    } else {
                        backup_data.push(format!("{}:ERROR:{}", key, result.error_message));
                    }
                }

                // Write combined data to backup key
                let combined_data = backup_data.join("|");
                Some(client.write(backup_key, combined_data))
            } else {
                None
            }
        } else {
            None
        }
    }
}

// Service for working with WebSocketClient objects
#[derive(uniffi::Object)]
pub struct WebSocketService {
    client_id: Mutex<Option<u32>>,
}

#[uniffi::export]
impl WebSocketService {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::new(Self {
            client_id: Mutex::new(None),
        })
    }

    pub fn set_client(&self, client_id: u32) {
        *self.client_id.lock().unwrap() = Some(client_id);
    }

    pub fn send_message(&self, message: String) -> Option<WebSocketResult> {
        if let Some(id) = *self.client_id.lock().unwrap() {
            if let Some(client) = get_websocket_client_registry().lock().unwrap().get(&id) {
                Some(client.send(message))
            } else {
                None
            }
        } else {
            None
        }
    }

    pub fn read_message(&self) -> Option<WebSocketResult> {
        if let Some(id) = *self.client_id.lock().unwrap() {
            if let Some(client) = get_websocket_client_registry().lock().unwrap().get(&id) {
                Some(client.read())
            } else {
                None
            }
        } else {
            None
        }
    }

    /// Send a message and then immediately read the response (demonstrating combined operations)
    pub fn send_and_read(&self, message: String) -> Option<WebSocketResult> {
        if let Some(id) = *self.client_id.lock().unwrap() {
            if let Some(client) = get_websocket_client_registry().lock().unwrap().get(&id) {
                // First send the message
                let send_result = client.send(message);
                if send_result.success {
                    // Then read the response
                    Some(client.read())
                } else {
                    Some(send_result)
                }
            } else {
                None
            }
        } else {
            None
        }
    }

    /// Send multiple messages in sequence and collect responses
    pub fn send_batch_messages(&self, messages: Vec<String>) -> Vec<WebSocketResult> {
        let mut results = Vec::new();

        if let Some(id) = *self.client_id.lock().unwrap() {
            if let Some(client) = get_websocket_client_registry().lock().unwrap().get(&id) {
                for message in messages {
                    let send_result = client.send(message);
                    results.push(send_result);

                    // Read response after each send
                    let read_result = client.read();
                    results.push(read_result);
                }
            }
        }

        results
    }

    /// Ping-pong pattern: send ping and read pong
    pub fn ping_pong(&self) -> Option<WebSocketResult> {
        if let Some(id) = *self.client_id.lock().unwrap() {
            if let Some(client) = get_websocket_client_registry().lock().unwrap().get(&id) {
                // Send ping
                let ping_result = client.send("PING".to_string());
                if ping_result.success {
                    // Read pong
                    Some(client.read())
                } else {
                    Some(ping_result)
                }
            } else {
                None
            }
        } else {
            None
        }
    }
}

// Registration functions
#[uniffi::export]
pub fn register_callback(callback: Box<dyn EventCallback>) -> u32 {
    let mut registry = get_registry().lock().unwrap();
    let mut next_id = get_next_id().lock().unwrap();

    let id = *next_id;
    *next_id += 1;

    registry.insert(id, Arc::from(callback));
    id
}

#[uniffi::export]
pub fn set_service_callback(service: Arc<CallbackService>, callback_id: u32) {
    *service.callback_id.lock().unwrap() = Some(callback_id);
}

#[uniffi::export]
pub fn unregister_callback(callback_id: u32) {
    get_registry().lock().unwrap().remove(&callback_id);
}

// Registration functions for DataProcessor objects
#[uniffi::export]
pub fn register_data_processor(processor: Box<dyn DataProcessor>) -> u32 {
    let mut registry = get_data_processor_registry().lock().unwrap();
    let mut next_id = get_next_id().lock().unwrap();

    let id = *next_id;
    *next_id += 1;

    registry.insert(id, Arc::from(processor));
    id
}

#[uniffi::export]
pub fn unregister_data_processor(processor_id: u32) {
    get_data_processor_registry()
        .lock()
        .unwrap()
        .remove(&processor_id);
}

// Registration functions for UserProfileManager objects
#[uniffi::export]
pub fn register_user_manager(manager: Box<dyn UserProfileManager>) -> u32 {
    let mut registry = get_user_manager_registry().lock().unwrap();
    let mut next_id = get_next_id().lock().unwrap();

    let id = *next_id;
    *next_id += 1;

    registry.insert(id, Arc::from(manager));
    id
}

#[uniffi::export]
pub fn unregister_user_manager(manager_id: u32) {
    get_user_manager_registry()
        .lock()
        .unwrap()
        .remove(&manager_id);
}

// Registration functions for StorageClient objects
#[uniffi::export]
pub fn register_storage_client(client: Box<dyn StorageClient>) -> u32 {
    let mut registry = get_storage_client_registry().lock().unwrap();
    let mut next_id = get_next_id().lock().unwrap();

    let id = *next_id;
    *next_id += 1;

    registry.insert(id, Arc::from(client));
    id
}

#[uniffi::export]
pub fn unregister_storage_client(client_id: u32) {
    get_storage_client_registry()
        .lock()
        .unwrap()
        .remove(&client_id);
}

// Registration functions for WebSocketClient objects
#[uniffi::export]
pub fn register_websocket_client(client: Box<dyn WebSocketClient>) -> u32 {
    let mut registry = get_websocket_client_registry().lock().unwrap();
    let mut next_id = get_next_id().lock().unwrap();

    let id = *next_id;
    *next_id += 1;

    registry.insert(id, Arc::from(client));
    id
}

#[uniffi::export]
pub fn unregister_websocket_client(client_id: u32) {
    get_websocket_client_registry()
        .lock()
        .unwrap()
        .remove(&client_id);
}

// Utility functions
#[uniffi::export]
pub fn create_test_data(size: u32) -> Vec<u8> {
    (0..size).map(|i| (i % 256) as u8).collect()
}

#[uniffi::export]
pub fn format_message(prefix: String, content: String) -> String {
    format!("{}: {}", prefix, content)
}

uniffi::setup_scaffolding!();

#[cfg(test)]
mod tests {
    use super::*;

    struct TestCallback;

    impl EventCallback for TestCallback {
        fn on_event(&self, event_type: String, message: String) {
            println!("Event: {} - {}", event_type, message);
        }

        fn on_data_received(&self, data: Vec<u8>) -> String {
            format!("Received {} bytes", data.len())
        }

        fn add_two_numbers(&self, a: i32, b: i32) -> i32 {
            a + b
        }
    }

    struct TestDataProcessor;

    impl DataProcessor for TestDataProcessor {
        fn process_item(&self, item: String) -> ProcessResult {
            ProcessResult {
                success: true,
                result: format!("Processed: {}", item),
                metadata: "test_processor".to_string(),
                timestamp: 123456789,
            }
        }

        fn validate_input(&self, input: String) -> bool {
            !input.is_empty() && input.len() < 100
        }

        fn transform_data(&self, data: Vec<String>) -> Vec<String> {
            data.into_iter()
                .map(|s| format!("TRANSFORMED_{}", s))
                .collect()
        }

        fn get_processor_name(&self) -> String {
            "TestDataProcessor".to_string()
        }
    }

    struct TestUserManager;

    impl UserProfileManager for TestUserManager {
        fn get_user_info(&self, user_id: u32) -> UserInfo {
            UserInfo {
                id: user_id,
                name: format!("User {}", user_id),
                email: format!("user{}@example.com", user_id),
                level: user_id % 10,
            }
        }

        fn update_preferences(&self, _user_id: u32, _preferences: UserPreferences) -> bool {
            true
        }

        fn calculate_score(&self, _user_id: u32, metrics: Vec<f64>) -> f64 {
            metrics.iter().sum::<f64>() / metrics.len() as f64
        }

        fn notify_user(&self, user_id: u32, message: String) {
            println!("Notification for user {}: {}", user_id, message);
        }
    }

    unsafe impl Send for TestCallback {}
    unsafe impl Sync for TestCallback {}
    unsafe impl Send for TestDataProcessor {}
    unsafe impl Sync for TestDataProcessor {}
    unsafe impl Send for TestUserManager {}
    unsafe impl Sync for TestUserManager {}

    struct TestStorageClient;

    impl StorageClient for TestStorageClient {
        fn read(&self, key: String) -> StorageResult {
            // Simulate reading from storage
            if key == "test_key" {
                StorageResult {
                    success: true,
                    data: "test_value".to_string(),
                    error_message: "".to_string(),
                    timestamp: 123456789,
                }
            } else {
                StorageResult {
                    success: false,
                    data: "".to_string(),
                    error_message: "Key not found".to_string(),
                    timestamp: 123456789,
                }
            }
        }

        fn write(&self, key: String, value: String) -> StorageResult {
            // Simulate writing to storage
            println!("Writing to storage: {} = {}", key, value);
            StorageResult {
                success: true,
                data: value,
                error_message: "".to_string(),
                timestamp: 123456789,
            }
        }
    }

    struct TestWebSocketClient;

    impl WebSocketClient for TestWebSocketClient {
        fn send(&self, message: String) -> WebSocketResult {
            // Simulate sending WebSocket message
            println!("Sending WebSocket message: {}", message);
            WebSocketResult {
                success: true,
                message: format!("Sent: {}", message),
                error_message: "".to_string(),
                connection_status: "connected".to_string(),
                timestamp: 123456789,
            }
        }

        fn read(&self) -> WebSocketResult {
            // Simulate reading WebSocket message
            WebSocketResult {
                success: true,
                message: "Echo response from server".to_string(),
                error_message: "".to_string(),
                connection_status: "connected".to_string(),
                timestamp: 123456789,
            }
        }
    }

    unsafe impl Send for TestStorageClient {}
    unsafe impl Sync for TestStorageClient {}
    unsafe impl Send for TestWebSocketClient {}
    unsafe impl Sync for TestWebSocketClient {}

    #[test]
    fn test_callback_service() {
        let service = CallbackService::new();
        assert_eq!(service.get_status(), "No callback registered");

        let callback_id = register_callback(Box::new(TestCallback));
        set_service_callback(service.clone(), callback_id);
        assert_eq!(service.get_status(), "Callback registered");

        service.trigger_event("test".to_string(), "Hello World".to_string());

        let test_data = create_test_data(10);
        let result = service.process_data(test_data);
        assert!(result.is_some());
        assert_eq!(result.unwrap(), "Received 10 bytes");

        unregister_callback(callback_id);
    }

    #[test]
    fn test_data_processor_service() {
        let processor = TestDataProcessor;
        let processor_id = register_data_processor(Box::new(processor));

        let service = DataProcessingService::new();
        service.set_processor(processor_id);

        // Test processing
        let result = service
            .process_single_item("test_item".to_string())
            .unwrap();
        assert!(result.success);
        assert_eq!(result.result, "Processed: test_item");

        // Test validation and processing
        let valid_result = service
            .validate_and_process("valid_input".to_string())
            .unwrap();
        assert!(valid_result.success);

        // Test batch transformation
        let input_data = vec!["item1".to_string(), "item2".to_string()];
        let transformed = service.batch_transform(input_data).unwrap();
        assert_eq!(transformed, vec!["TRANSFORMED_item1", "TRANSFORMED_item2"]);

        // Test processor info
        assert_eq!(service.get_processor_info().unwrap(), "TestDataProcessor");

        unregister_data_processor(processor_id);
    }

    #[test]
    fn test_user_service() {
        let manager = TestUserManager;
        let manager_id = register_user_manager(Box::new(manager));

        let service = UserService::new();
        service.set_manager(manager_id);

        // Test getting user info
        let user_info = service.get_user(123).unwrap();
        assert_eq!(user_info.id, 123);
        assert_eq!(user_info.name, "User 123");
        assert_eq!(user_info.email, "user123@example.com");

        // Test updating preferences
        let preferences = UserPreferences {
            theme: "dark".to_string(),
            notifications_enabled: true,
            language: "en".to_string(),
            auto_save: false,
        };
        assert!(service.update_user_preferences(123, preferences).unwrap());

        // Test score calculation
        let metrics = vec![85.5, 92.0, 78.3];
        let score = service.calculate_user_score(123, metrics).unwrap();
        assert!((score - 85.26666666666667).abs() < 0.001);

        // Test notification (just verify it doesn't panic)
        service.send_notification(123, "Test notification".to_string());

        unregister_user_manager(manager_id);
    }

    #[test]
    fn test_storage_service() {
        let client = TestStorageClient;
        let client_id = register_storage_client(Box::new(client));

        let service = StorageService::new();
        service.set_client(client_id);

        // Test reading data
        let read_result = service.read_data("test_key".to_string()).unwrap();
        assert!(read_result.success);
        assert_eq!(read_result.data, "test_value");

        // Test writing data
        let write_result = service
            .write_data("new_key".to_string(), "new_value".to_string())
            .unwrap();
        assert!(write_result.success);
        assert_eq!(write_result.data, "new_value");

        // Test copy operation (read then write)
        let copy_result = service
            .copy_data("test_key".to_string(), "copied_key".to_string())
            .unwrap();
        assert!(copy_result.success);
        assert_eq!(copy_result.data, "test_value");

        // Test backup multiple keys
        let keys = vec!["test_key".to_string(), "nonexistent_key".to_string()];
        let backup_result = service
            .backup_multiple_keys(keys, "backup_key".to_string())
            .unwrap();
        assert!(backup_result.success);

        unregister_storage_client(client_id);
    }

    #[test]
    fn test_websocket_service() {
        let client = TestWebSocketClient;
        let client_id = register_websocket_client(Box::new(client));

        let service = WebSocketService::new();
        service.set_client(client_id);

        // Test sending message
        let send_result = service
            .send_message("Hello WebSocket!".to_string())
            .unwrap();
        assert!(send_result.success);
        assert_eq!(send_result.message, "Sent: Hello WebSocket!");

        // Test reading message
        let read_result = service.read_message().unwrap();
        assert!(read_result.success);
        assert_eq!(read_result.message, "Echo response from server");

        // Test send and read operation
        let send_read_result = service.send_and_read("Ping".to_string()).unwrap();
        assert!(send_read_result.success);
        assert_eq!(send_read_result.message, "Echo response from server");

        // Test ping-pong
        let ping_pong_result = service.ping_pong().unwrap();
        assert!(ping_pong_result.success);

        // Test batch messages
        let messages = vec!["msg1".to_string(), "msg2".to_string()];
        let batch_results = service.send_batch_messages(messages);
        assert_eq!(batch_results.len(), 4); // 2 sends + 2 reads

        unregister_websocket_client(client_id);
    }

    #[test]
    fn test_utility_functions() {
        let data = create_test_data(5);
        assert_eq!(data.len(), 5);

        let message = format_message("INFO".to_string(), "Test message".to_string());
        assert_eq!(message, "INFO: Test message");
    }
}
