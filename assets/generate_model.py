import tensorflow as tf
import numpy as np

# Create a simple model
model = tf.keras.Sequential([
    tf.keras.layers.Dense(16, activation='relu', input_shape=(3,)),
    tf.keras.layers.Dense(8, activation='relu'),
    tf.keras.layers.Dense(3, activation='softmax')
])

# Compile the model
model.compile(optimizer='adam',
              loss='categorical_crossentropy',
              metrics=['accuracy'])

# Generate some synthetic training data
np.random.seed(42)
n_samples = 1000

# Generate random input data
temperature = np.random.uniform(36, 40, n_samples)
spo2 = np.random.uniform(70, 100, n_samples)
heart_rate = np.random.uniform(40, 200, n_samples)

# Normalize inputs
temperature_norm = (temperature - 36.0) / (40.0 - 36.0)
spo2_norm = (spo2 - 70.0) / (100.0 - 70.0)
heart_rate_norm = (heart_rate - 40.0) / (200.0 - 40.0)

X = np.column_stack((temperature_norm, spo2_norm, heart_rate_norm))

# Generate labels based on some rules
y = np.zeros((n_samples, 3))
for i in range(n_samples):
    if (temperature[i] > 38.5 or spo2[i] < 90 or heart_rate[i] > 150):
        y[i, 2] = 1  # High risk
    elif (temperature[i] > 37.5 or spo2[i] < 95 or heart_rate[i] > 120):
        y[i, 1] = 1  # Medium risk
    else:
        y[i, 0] = 1  # Low risk

# Train the model
model.fit(X, y, epochs=50, batch_size=32, verbose=1)

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save the model
with open('heart_risk_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("Model saved as heart_risk_model.tflite") 