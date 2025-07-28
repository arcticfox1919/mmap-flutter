#ifndef MIO_WRAPPER_H
#define MIO_WRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>
#include <stdint.h>

// Symbol visibility macros
#if defined(_WIN32) || defined(__CYGWIN__)
    #ifdef MIO_WRAPPER_BUILDING_DLL
        #define MIO_WRAPPER_API __declspec(dllexport)
    #else
        #define MIO_WRAPPER_API __declspec(dllimport)
    #endif
#else
    #if defined(__GNUC__) || defined(__clang__)
        #define MIO_WRAPPER_API __attribute__((visibility("default")))
    #else
        #define MIO_WRAPPER_API
    #endif
#endif

// Forward declaration of opaque handle
typedef struct MioMmapHandle MioMmapHandle;

// Error codes
typedef enum {
    MIO_SUCCESS = 0,
    MIO_ERROR_INVALID_ARGUMENT = 1,
    MIO_ERROR_FILE_NOT_FOUND = 2,
    MIO_ERROR_PERMISSION_DENIED = 3,
    MIO_ERROR_OUT_OF_MEMORY = 4,
    MIO_ERROR_MAPPING_FAILED = 5,
    MIO_ERROR_INVALID_HANDLE = 6,
    MIO_ERROR_UNKNOWN = 7
} MioError;

// Access modes
typedef enum {
    MIO_ACCESS_READ = 0,
    MIO_ACCESS_WRITE = 1
} MioAccessMode;

/**
 * Create a memory map from a file path
 * @param path Path to the file to map
 * @param access_mode Access mode (MIO_ACCESS_READ or MIO_ACCESS_WRITE)
 * @param offset Offset in bytes from the beginning of the file
 * @param length Length to map (0 for entire file)
 * @param error Pointer to store error code
 * @return Handle to the memory map or NULL on error
 */
MIO_WRAPPER_API MioMmapHandle* mio_mmap_create_from_path(const char* path, 
                                         MioAccessMode access_mode,
                                         size_t offset, 
                                         size_t length, 
                                         MioError* error);

/**
 * Create a memory map from a file handle
 * @param file_handle File handle (int on Unix, HANDLE on Windows)
 * @param access_mode Access mode (MIO_ACCESS_READ or MIO_ACCESS_WRITE)
 * @param offset Offset in bytes from the beginning of the file
 * @param length Length to map (0 for entire file)
 * @param error Pointer to store error code
 * @return Handle to the memory map or NULL on error
 */
MIO_WRAPPER_API MioMmapHandle* mio_mmap_create_from_handle(intptr_t file_handle,
                                          MioAccessMode access_mode,
                                          size_t offset,
                                          size_t length,
                                          MioError* error);

/**
 * Get the data pointer from the memory map
 * @param handle Handle to the memory map
 * @return Pointer to the mapped data or NULL if invalid
 */
MIO_WRAPPER_API const uint8_t* mio_mmap_get_data(MioMmapHandle* handle);

/**
 * Get the writable data pointer from the memory map (only for write-enabled maps)
 * @param handle Handle to the memory map
 * @return Pointer to the mapped data or NULL if invalid or read-only
 */
MIO_WRAPPER_API uint8_t* mio_mmap_get_data_writable(MioMmapHandle* handle);

/**
 * Get the size of the mapped region
 * @param handle Handle to the memory map
 * @return Size in bytes, 0 if invalid handle
 */
MIO_WRAPPER_API size_t mio_mmap_get_size(MioMmapHandle* handle);

/**
 * Get the actual mapped length (may be larger due to page alignment)
 * @param handle Handle to the memory map
 * @return Actual mapped length in bytes, 0 if invalid handle
 */
MIO_WRAPPER_API size_t mio_mmap_get_mapped_length(MioMmapHandle* handle);

/**
 * Check if the memory map is open
 * @param handle Handle to the memory map
 * @return 1 if open, 0 if not
 */
MIO_WRAPPER_API int mio_mmap_is_open(MioMmapHandle* handle);

/**
 * Check if the memory map is mapped
 * @param handle Handle to the memory map
 * @return 1 if mapped, 0 if not
 */
MIO_WRAPPER_API int mio_mmap_is_mapped(MioMmapHandle* handle);

/**
 * Sync the memory map to disk (for write-enabled maps)
 * @param handle Handle to the memory map
 * @return Error code
 */
MIO_WRAPPER_API MioError mio_mmap_sync(MioMmapHandle* handle);

/**
 * Destroy the memory map and free resources
 * @param handle Handle to the memory map
 */
MIO_WRAPPER_API void mio_mmap_destroy(MioMmapHandle* handle);

/**
 * Get error message string
 * @param error Error code
 * @return Error message string
 */
MIO_WRAPPER_API const char* mio_get_error_message(MioError error);

/**
 * Get the library version string
 * @return Version string in format "major.minor.patch"
 */
MIO_WRAPPER_API const char* mio_get_version(void);

#ifdef __cplusplus
}
#endif

#endif // MIO_WRAPPER_H
