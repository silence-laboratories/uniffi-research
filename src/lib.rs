use std::collections::HashMap;
use std::sync::{Arc, Mutex, OnceLock};

// Trait for callback functions that can be implemented by Kotlin/Swift
#[uniffi::export(callback_interface)]
pub trait EventCallback: Send + Sync {
    fn on_event(&self, event_type: String, message: String);
    fn on_data_received(&self, data: Vec<u8>) -> String;
}

// Global registry for callbacks
static CALLBACK_REGISTRY: OnceLock<Mutex<HashMap<u32, Arc<dyn EventCallback>>>> = OnceLock::new();
static NEXT_ID: OnceLock<Mutex<u32>> = OnceLock::new();

fn get_registry() -> &'static Mutex<HashMap<u32, Arc<dyn EventCallback>>> {
    CALLBACK_REGISTRY.get_or_init(|| Mutex::new(HashMap::new()))
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
    }

    unsafe impl Send for TestCallback {}
    unsafe impl Sync for TestCallback {}

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
    fn test_utility_functions() {
        let data = create_test_data(5);
        assert_eq!(data.len(), 5);

        let message = format_message("INFO".to_string(), "Test message".to_string());
        assert_eq!(message, "INFO: Test message");
    }
}
