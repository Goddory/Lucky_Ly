using UnityEngine;
using GLTFast;
using System.IO;

public class AvatarController : MonoBehaviour
{
    private GameObject currentAvatar;
    
    // Gọi từ Flutter truyền đường dẫn Local Path của SQLite
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
        bool success = await gltf.Load("file://" + path);
        if (success)
        {
            bool instantiateSuccess = await gltf.InstantiateMainSceneAsync(currentAvatar.transform);
            if (instantiateSuccess)
            {
                Debug.Log("Avatar Loaded Successfully!");
                // Optionally setup animations or modify materials here
            }
        }
        else
        {
            Debug.LogError("Failed to load glTF.");
        }
    }
}
