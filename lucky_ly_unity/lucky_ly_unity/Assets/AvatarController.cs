using UnityEngine;
using GLTFast;
using System.IO;

public class AvatarController : MonoBehaviour
{
    private GameObject currentAvatar;
    
    // Gọi từ Flutter truyền đường dẫn Local Path từ SQLite
    public void LoadAvatarFromPath(string path)
    {
        Debug.Log("Unity LoadAvatarFromPath called: " + path);
        if (File.Exists(path))
        {
            LoadGltf(path);
        }
        else
        {
            Debug.LogError("Avatar GLB file not found at: " + path);
        }
    }

    private async void LoadGltf(string path)
    {
        if (currentAvatar != null)
        {
            Destroy(currentAvatar);
        }

        currentAvatar = new GameObject("AvatarRender");
        currentAvatar.transform.SetParent(this.transform, false);

        var gltf = new GltfImport();
        // Unity file path prefix for local files
        string fileUrl = "file://" + path;
        
        // glTFast 5.x+ uses Load
        bool success = await gltf.Load(fileUrl);
        if (success)
        {
            bool instantiateSuccess = await gltf.InstantiateMainSceneAsync(currentAvatar.transform);
            if (instantiateSuccess)
            {
                Debug.Log("Avatar Loaded Successfully!");
            }
        }
        else
        {
            Debug.LogError("Failed to load glTF from: " + fileUrl);
        }
    }
}
